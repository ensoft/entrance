# Base class for a CLI ThreadedConnection
#
# Copyright (c) 2018 Ensoft Ltd

import re
from entrance.connection.threaded import ThreadedConnection


class ThreadedCLIConnection(ThreadedConnection):
    """
    Base class for a ThreadedConnection whose worker thread
    maintains a CLI session
    """

    async def send(self, data, override=False):
        """
        Send some data into the connection
        """
        return await self._request("send", override, data)

    async def recv(self, nbytes=0, override=False):
        """
        Wait for some data from the connection. Note that this will cause the
        worker thread to block until some data is available. If nbytes == 0 then
        get all the data available at first shot.
        """
        return await self._request("recv", override, nbytes)

    async def settimeout(self, timeout, override=False):
        """
        Set a timeout on send/recv operations. If hit, recv will just return a
        shorter or empty response. Sends will silently drop.
        """
        return await self._request("settimeout", override, timeout)

    # Regexps for _expect_prompt below
    _prompt = re.compile(r"(.*)RP/0/(RP)?0/CPU0:[^\r\n]*?#", re.DOTALL)
    _interesting = re.compile(r"[^\n]*\n[^\n]* UTC\r\n(.*)", re.DOTALL)

    async def expect_prompt(self, strip_top=False, override=False):
        """
        Waits for a prompt, and returns all the characters up to that point
        (optionally also stripping off an initial line and timestamp)
        """
        buf = bytes()
        while True:
            buf += await self.recv(override=override)
            m = self._prompt.match(buf.decode())
            if m:
                result = m.group(1)
                if strip_top:
                    m = self._interesting.match(result)
                    if m:
                        result = m.group(1)
                return result
