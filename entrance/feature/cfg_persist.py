# Persistence feature
#
# Copyright (c) 2018 Ensoft Ltd

import ujson
from .cfg_base import ConfiguredFeature

class PersistFeature(ConfiguredFeature):
    """
    Feature that saves and retrieves arbitrary data chunks for the frontend app.
    Intended for small bits of data (eg preferences) - load/save operations
    are not expected to be efficient. This assumes it is called only from
    one thread (the main event loop thread). Each endpoint (for each userid)
    can save or load one JSONable value.
    """
    #
    # Schema
    #
    name = 'persist'

    requests = {'persist_save': ['userid', 'endpoint', 'data'],
                'persist_load': ['userid', 'endpoint', 'default']}

    config = {'filename': 'persist.json'}

    #
    # Implementation
    #
    async def do_persist_save(self, userid, endpoint, data):
        """
        Save a table, overwriting it if already present
        """
        db = self._load_db()
        if userid not in db:
            db[userid] = {endpoint: data}
        else:
            db[userid][endpoint] = data
        self._save_db(db)

    async def do_persist_load(self, userid, endpoint, default):
        """
        Load a table. If not present then return the specified default
        """
        db = self._load_db()
        try:
            data = db[userid][endpoint]
        except KeyError:
            data = default
        return self._result('persist_load', data=data)

    def _load_db(self):
        """
        Load the entire database
        """
        try:
            with open(self.config['filename']) as f:
                return ujson.loads(f.read())
        except FileNotFoundError:
            return {}
        except ValueError as e:
            raise Exception("{} is invalid json: {}".format(
                self.config['filename'], e))

    def _save_db(self, db):
        """
        Save the entire database
        """
        with open(self.config['filename'], 'w') as f:
            f.write(ujson.dumps(db, indent=4))
