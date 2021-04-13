# Persistence feature
#
# Copyright (c) 2018 Ensoft Ltd

from collections import defaultdict
import ujson
from .cfg_base import ConfiguredFeature

# Remember which active websockets have requested data for a given channel, so
# that any changes can get published to everyone.
# userid name -> channel name -> set of interested PersistFeature instances
listeners = defaultdict(lambda: defaultdict(set))


class PersistFeature(ConfiguredFeature):
    """
    Feature that saves and retrieves arbitrary data chunks for the frontend app.
    Intended for small bits of data (eg preferences) - load/save operations
    are not expected to be efficient. This assumes it is called only from
    one thread (the main event loop thread). Each channel (for each userid)
    can save or load one JSONable value.
    """

    #
    # Schema
    #
    name = "persist"

    requests = {
        "persist_save_async": ["userid", "channel", "data"],
        "persist_save_sync": ["userid", "channel", "data"],
        "persist_load": ["userid", "channel", "default"],
    }

    config = {"filename": "persist.json"}

    # Unsubscribe ourselves from everything on close
    def close(self):
        for userid in listeners.values():
            for channels in userid.values():
                channels.remove(self)

    #
    # Implementation
    #
    async def do_persist_save_async(self, userid, channel, data):
        """
        Save a table, overwriting it if already present
        """
        db = self._load_db()
        if userid not in db:
            db[userid] = {channel: data}
        else:
            db[userid][channel] = data
        self._save_db(db)

        # Notify any other peer connections that care about this
        for obj in listeners[userid][channel]:
            if obj != self:
                await obj._notify(nfn_type="persist_load", channel=channel, data=data)

    async def do_persist_save_sync(self, userid, channel, data):
        """
        Same as do_persist_save, with a synchronous reply.
        """
        try:
            await self.do_persist_save_async(userid, channel, data)
            return self._rpc_success("")
        except Exception as e:
            return self._rpc_failure(e)

    async def do_persist_load(self, userid, channel, default):
        """
        Load a table. If not present then return the specified default
        """
        listeners[userid][channel].add(self)  # subscribe
        db = self._load_db()
        try:
            data = db[userid][channel]
        except KeyError:
            data = default
        return self._result("persist_load", data=data)

    def _load_db(self):
        """
        Load the entire database
        """
        try:
            # tsk - synchronous file I/O. ho hum.
            with open(self.config["filename"]) as f:
                return ujson.loads(f.read())
        except FileNotFoundError:
            return {}
        except ValueError as e:
            raise Exception("{} is invalid json: {}".format(self.config["filename"], e))

    def _save_db(self, db):
        """
        Save the entire database
        """
        # tsk - synchronous file I/O again. la di da.
        with open(self.config["filename"], "w") as f:
            f.write(ujson.dumps(db, indent=4))
