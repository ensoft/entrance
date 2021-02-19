import runpy

from entrance.connection import *
from entrance.exceptions import *
from entrance.feature import *
from entrance.ws_handler import *


def main():
    """
    Run the entrance module (via __main__.py) in the current Python process.
    """
    runpy.run_module("entrance", run_name="__main__")
