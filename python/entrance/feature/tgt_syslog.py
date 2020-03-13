# Syslog monitoring feature
#
# Copyright (c) 2018 Ensoft Ltd

import re, time

from .._util import events
from .tgt_base import TargetFeature


class SyslogFeature(TargetFeature):
    """
    Feature that monitors for syslogs, with optional debugs and filtering.
    """

    #
    # Schema
    #
    name = "syslog"
    notifications = ["syslog"]

    #
    # Implementation
    #
    async def connect(self, conn_factory):
        """
        Set up our connection to the router
        """
        self.connection = await conn_factory.get_cli_connection(
            "syslog", finalizer=self.finalizer
        )
        self.add_connection(self.connection, from_scratch=True)

    async def finalizer(self):
        """
        Finalize a new connection
        """
        # First handle any filters/debug settings from the start_feature req
        filters = self.original_req.get("filters", [])
        if len(filters) == 0:
            # just drop empty lines
            filters = [r"\S"]
        regexp = re.compile("|".join(["({})".format(f) for f in filters]))
        nfn = {"nfn_type": "syslog", "channel": self.original_req["channel"]}
        if "id" in self.original_req:
            nfn["id"] = self.original_req["id"]

        # Then do the expect stuff to get us ready to go
        await self.connection.send("undebug all all-tty\n", override=True)
        await self.connection.expect_prompt(override=True)
        await self.connection.send("terminal monitor\n", override=True)
        await self.connection.expect_prompt(override=True)
        for debug in self.original_req.get("debugs", []):
            await self.connection.send("{}\n".format(debug), override=True)
            await self.connection.expect_prompt(override=True)

        # We need to return at this point, so the connection transitions
        # from FINALIZING to CONNECTED, so tee up our mini event loop for later
        events.create_checked_task(self._event_loop(regexp, nfn))

    async def _event_loop(self, regexp, nfn):
        """
        Sit and wait for syslogs/debugs to come in
        """
        # poll event loop for disconnect requests occasionally
        await self.connection.settimeout(1)

        # enter event loop
        while not self.connection.terminate:
            data = (await self.connection.recv()).decode()
            for syslog in data.split("\n"):
                if regexp.search(syslog):
                    nfn["result"] = syslog
                    nfn["time"] = time.time()
                    await self._notify(**nfn)
