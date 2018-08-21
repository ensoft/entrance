# Base class for Connection and ConnectionFactory
#
# Copyright (c) 2018 Ensoft Ltd

import asyncio
from enum import IntEnum, unique

@unique
class ConState(IntEnum):
    # Order is important: overall connection state is the max of the
    # states of the individual connections
    DISCONNECTED = 0
    CONNECTED = 1
    FAILURE_WHILE_DISCONNECTING = 2
    FINALIZING = 3
    CONNECTING = 4
    DISCONNECTING = 5
    RECONNECTING_AFTER_FAILURE = 6
    FAILED_TO_CONNECT = 7

    def is_failure(self):
        return self in (self.FAILURE_WHILE_DISCONNECTING,
                        self.RECONNECTING_AFTER_FAILURE,
                        self.FAILED_TO_CONNECT)

class ConnectionFactory():
    """
    Factory that knows about a single router, and can produce Connection
    objects on demand. Each Connection object represents a connection to that
    same router, that can be used for different purposes concurrently.
    """
    def __init__(self, **kwargs):
        self.kwargs = kwargs

    async def get_cli_connection(self, connection_name, finalizer=None):
        """
        Create a new CLI exec connection, and return a corresponding
        CLIConnection object
        """
        con = self.cli_connection_cls(self, connection_name, finalizer)
        await con.connect(**self.kwargs)
        return con

    async def get_netconf_connection(self, connection_name, finalizer=None):
        """
        Create a new Netconf connection, and return a corresponding
        NetconfConnection object
        """
        con = self.netconf_connection_cls(self, connection_name, finalizer)
        await con.connect(**self.kwargs)
        return con

class Connection():
    """
    Base class representing a single router connection
    """
    def __init__(self, factory, name, finalizer, **kwargs):
        self.factory = factory
        self.name = name
        self.finalizer = finalizer
        self.state = ConState.DISCONNECTED
        self.kwargs = kwargs
        self.state_listeners = []

    def add_state_listener(self, listener):
        """
        Add a callback to be notified when connection changes state
        """
        self.state_listeners.append(listener)

    async def connect(self):
        # documentation only, implemented by subclasses
        pass

    async def disconnect(self):
        # documentation only, implemented by subclasses
        pass

    async def _set_state(self, state):
        """
        Helper method to set the connection state.
        SUBCLASSES MUST ALWAYS USE THIS, DON'T JUST SET THE STATE DIRECTLY
        """
        # Actually change state
        self.state = state

        # Notify listeners
        for listener in self.state_listeners:
            await listener(self)

        # Call the finalizer if required
        if state == ConState.FINALIZING:
            async def finalize():
                if self.finalizer is not None:
                    await self.finalizer()
                await self._set_state(ConState.CONNECTED)
            asyncio.ensure_future(finalize())
