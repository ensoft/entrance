from .base import *
from .ssh import *

# Map of connection type strings to factory classes
connection_factory_by_name = {"ssh": SSHConnectionFactory}
