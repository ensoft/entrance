# Base class that represents a protocol sesssion owned by a separate
# synchronous thread
#
# Copyright (c) 2018 Ensoft Ltd

import logging, re, threading
import asyncio, janus

from .base import Connection, ConState
from .._util import events

log = logging.getLogger(__name__)


class ConnectionError(Exception):
    pass


class ThreadedConnection(Connection):
    """
    Base class representing a Connection where there is a dedicated thread to
    interact with the peer, which is an implementation choice that is hidden
    from the regular asyncio API as per all other Connection types
    """

    def __init__(self, factory, name, finalizer=None):
        """
        Create a session object
        """
        super().__init__(factory, name, finalizer)
        self.request_q = janus.Queue()
        self.result_q = janus.Queue()
        self.thread = None
        self.event_loop_task = None

    async def connect(self, **kwargs):
        """
        Initiate a connection
        """
        self.thread = threading.Thread(
            name=self.__class__, daemon=True, target=self._thread_main, kwargs=kwargs
        )
        self.thread.start()
        self.event_loop_task = events.create_checked_task(self._event_loop())

    async def disconnect(self):
        """
        Request a disconnection
        """
        await self._set_state(ConState.DISCONNECTING)
        await self._request("disconnect", override=True)

        # Give the thread a few seconds, then try to mop things up
        await asyncio.sleep(5)
        if self.state != ConState.DISCONNECTED:
            log.info("Cancelling {} task for slow disconnection".format(self.name))
            state = ConState.FAILURE_WHILE_DISCONNECTING
            state.failure_reason = "Disconnect timeout"
            await self._set_state(state)
        self.event_loop_task.cancel()
        self.event_loop_task = None

    async def _event_loop(self):
        # Permanently wait for any responses to requests that are provided
        # by the worker thread, and dispatch the responses back appropriately
        while True:
            try:
                result, fut = await self.result_q.async_q.get()
                if isinstance(result, ConState):
                    await self._set_state(result)
                elif isinstance(result, Exception):
                    fut.set_exception(result)
                else:
                    fut.set_result(result)
            except Exception as e:
                log.error(
                    "Exception during connection/threaded/_event_loop: {}"
                    " (see debug.log for details)".format(e)
                )
                log.debug(
                    "_event_loop exception details", exc_info=True, stack_info=True
                )

    async def _request(self, action, override, *args):
        """
        Queue a request to the worker thread
        """
        # The override flag is intended for two purposes:
        #
        # - forcing a manual disconnect from any state
        # - allowing a finalizer to do operations on a newly minted connection
        #   before regular clients can do so
        #
        # However, if the flag is set, we just go and try it anyway. So if
        # it's set for a purpose that might cause an exception, you're going
        # to get an exception.
        if self.state != ConState.CONNECTED and not override:
            raise ConnectionError(
                "Connection {} in state {} so cannot {}({})".format(
                    self.name, self.state.name, action, args
                )
            )
        fut = asyncio.Future()
        await self.request_q.async_q.put((action, args, fut))
        await asyncio.wait([fut], return_when=asyncio.ALL_COMPLETED)
        return fut.result()

    def _update_state(self, state, failure_reason=None):
        """
        Push a connection state update to the main thread
        """
        if failure_reason is not None:
            state.failure_reason = failure_reason
        self.result_q.sync_q.put((state, None))

    def _thread_main(self, **kwargs):
        """
        Kick off a session in the new thread
        """
        self.terminate = False
        initiate_connect = True
        self._update_state(ConState.CONNECTING)

        # Event loop for this session
        while not self.terminate:
            # Connect if required
            if initiate_connect:
                try:
                    self._handle_connect(**kwargs)
                except Exception as reason:
                    err = str(reason)
                    log.error(
                        "Exception in _handle_connect: "
                        + err
                        + " (see debug.log for details)"
                    )
                    log.debug("Exception details", exc_info=True, stack_info=True)
                    m = re.search("<.*>: *(.+)", err)
                    failure_reason = m.group(1) if m else err
                    self._update_state(
                        ConState.FAILED_TO_CONNECT, failure_reason=failure_reason
                    )
                initiate_connect = False

            # Block for a request
            action, args, fut = self.request_q.sync_q.get()
            if not (action == "recv" and len(args) == 1 and args[0] == 0):
                log.debug("{} worker thread req: {}{}".format(self.name, action, args))

            # Do the request
            handler = getattr(self, "_handle_" + action)
            try:
                result = handler(*args)
            except Exception as e:
                # Err on the side of caution for customer demo purposes -
                # ditch the whole thing lazily (leaking all sorts of stuff) and
                # blindly reconnect. We could instead just return the error
                # and carry on - probably more correct once we have confidence
                # that things generally do the right thing.
                failure_reason = "Handler for {}({}) crashed: {}".format(
                    action, args, e
                )
                log.warning("%s (see debug.log for details)", failure_reason)
                log.debug("Exception details", exc_info=True, stack_info=True)
                self._update_state(
                    ConState.RECONNECTING_AFTER_FAILURE, failure_reason=failure_reason
                )
                initiate_connect = True
                result = e

            # Return the result
            self.result_q.sync_q.put((result, fut))

        log.debug("%s thread main exit", self.name)
