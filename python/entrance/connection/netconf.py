# Base class for a Netconf ThreadedConnection
#
# Copyright (c) 2018 Ensoft Ltd

from entrance.connection.threaded import ThreadedConnection


class ThreadedNCConnection(ThreadedConnection):
    """
    Base class for a ThreadedConnection whose worker thread
    is a ncclient.manager session. Just add a connection.
    """

    async def get(self, xml_filter, override=False):
        """
        Issue a Netconf "get" request in the worker thread
        """
        return await self._request("get", override, xml_filter)

    async def get_config(self, xml_filter, override=False):
        """
        Issue a Netconf "get-config" request in the worker thread
        """
        if xml_filter.strip() == "":
            xml_filter = None
        return await self._request("get_config", override, xml_filter)

    async def edit_config(self, xml_config, override=False):
        """
        Issue a Netconf "edit-config" request in the worker thread
        """
        return await self._request("edit_config", override, xml_config)

    async def commit(self, override=False):
        """
        Issue a Netconf "commit" request in the worker thread
        """
        return await self._request("commit", override)

    async def validate(self, override=False):
        """
        Issue a Netconf "validate" request in the worker thread
        """
        return await self._request("validate", override)

    async def discard_changes(self, override=False):
        """
        Issue a discard-changes request in the worker thread
        """
        return await self._request("discard_changes", override)

    def _handle_get(self, xml_filter):
        """
        Netconf "get" request
        """
        return self.mgr.get(filter=xml_filter)

    def _handle_get_config(self, xml_filter):
        """
        Netconf "get-config" request
        """
        return self.mgr.get_config(source="running", filter=xml_filter)

    def _handle_edit_config(self, xml_config):
        """
        Netconf "edit-config" request
        """
        self._handle_discard_changes()
        return self.mgr.edit_config(target="candidate", config=xml_config)

    def _handle_commit(self):
        """
        Netconf "commit" request
        """
        return self.mgr.commit()

    def _handle_validate(self):
        """
        Netconf "validate" request
        """
        return self.mgr.validate(source="candidate")

    def _handle_discard_changes(self):
        """
        Discard current changes
        """
        return self.mgr.discard_changes()
