# Maintain a persistent ssh connection to an individual router
#
# Copyright (c) 2018 Ensoft Ltd

import os, socket, sys, time

try:
    import paramiko
    import ncclient.manager as nc_mgr
    from ncclient.operations import RaiseMode
    from entrance.connection.base import ConnectionFactory, ConState
    from entrance.connection.cli import ThreadedCLIConnection
    from entrance.connection.netconf import ThreadedNCConnection
except ImportError:
    # Very cheesy way to permit the majority case (router interaction
    # features not required) to install the entrance package without
    # incurring all the complex dependencies from the router features.
    # Better solutions welcomed!
    class Fail:
        def __init__(self, *args, **kwargs):
            print(
                "\n\n\n\n* To use router features, re-install depending",
                'on the package\n* name "entrance[with-router-features]",',
                'not simply "entrance".\n* This installation does not',
                "have the required dependencies.\n\n\n",
                file=sys.stderr,
            )
            os.abort()

    ThreadedCLIConnection = Fail
    ThreadedNCConnection = Fail
    ConnectionFactory = Fail

__all__ = ["SSHConnectionFactory"]

BUF_SIZE = 10000  # ssh max buffer size


class SSHCLIConnection(ThreadedCLIConnection):
    """
    SSH CLI Connection
    """

    def _handle_connect(self, **creds):
        """
        Initiate a persistent ssh connection, in the paramiko thread.
        """
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        kwargs = {
            "username": creds["username"],
            "port": int(creds.get("ssh_port", "22")),
            "allow_agent": False,
            "look_for_keys": False,
        }
        if "ssh_key" in creds:
            kwargs["key_filename"] = creds["ssh_key"]
        else:
            kwargs["password"] = creds.get("password", "")
        self.ssh.connect(creds["host"], **kwargs)
        self.channel = self.ssh.invoke_shell(width=0, height=0)

        # Swallow any initial stuff
        self.channel.send("\n")
        while True:
            z = self.channel.recv(BUF_SIZE).decode()
            if "#" in z:
                break
            time.sleep(1)

        # Should be sane now!
        self._update_state(ConState.FINALIZING)

    def _handle_settimeout(self, timeout):
        """
        Set a timeout on send/recv requests
        """
        self.channel.settimeout(timeout)

    def _handle_disconnect(self):
        """
        Kill the connection
        """
        try:
            self.ssh.close()
            self._update_state(ConState.DISCONNECTED)
        except Exception as e:
            self._update_state(ConState.FAILURE_WHILE_DISCONNECTING, str(e))
        self.terminate = True

    def _handle_send(self, data):
        """
        Send some data
        """
        self.channel.send(data)

    def _handle_recv(self, nbytes):
        """
        Wait for some data
        """
        try:
            if nbytes > 0:
                buf = self.channel.recv(nbytes)
            else:
                buf = self.channel.recv(BUF_SIZE)
                while self.channel.recv_ready():
                    buf += self.channel.recv(BUF_SIZE)
            return buf
        except socket.timeout:
            return bytes()


class SSHNCConnection(ThreadedNCConnection):
    """
    SSH Netconf Connection
    """

    def _handle_connect(self, **creds):
        """
        Initiate a persistent ssh connection, in the worker thread
        """
        kwargs = {
            "username": creds["username"],
            "port": creds.get("netconf_port", 830),
            "device_params": {"name": "iosxr"},
        }
        if "ssh_key" in creds:
            kwargs["key_filename"] = creds["ssh_key"]
        else:
            kwargs["password"] = creds.get("password", "")
        try:
            self.mgr = nc_mgr.connect_ssh(creds["host"], **kwargs)
            self.mgr.raise_mode = RaiseMode.NONE
            self._update_state(ConState.FINALIZING)
        except Exception as e:
            self.mgr = None
            self._update_state(ConState.FAILED_TO_CONNECT, str(e))

    def _handle_disconnect(self):
        """
        Kill the connection
        """
        try:
            if self.mgr is not None:
                self.mgr.close_session()
            self._update_state(ConState.DISCONNECTED)
        except Exception as e:
            self._update_state(ConState.FAILURE_WHILE_DISCONNECTING, str(e))
        self.terminate = True


class SSHConnectionFactory(ConnectionFactory):
    """
    ConnectionFactory for a regular router
    """

    cli_connection_cls = SSHCLIConnection
    netconf_connection_cls = SSHNCConnection
