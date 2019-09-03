# Setup definition for EnTrance package
#
# To upload a new version to PyPi using nix:
#
# - `nix-shell -p 'python3.withPackages(p:[p.pip p.setuptools p.twine])'`
# - `python3 setup.py sdist`
# - If that all looks ok, `twine upload dist/*`
#
# I suspect there's something else that should be happening with wheel, but
# this seems to work.

import os, sys
from setuptools import find_packages, setup

# Router features require heavy dependencies, so include only when actually required
# via depending on 'entrance[with-router-features' rather than just 'entrance'.
router_feature_deps = ['janus', 'ncclient', 'paramiko']

# Acutally, an icky second way of including the optional dependencies would just be
# to rewrite this from '[]' to 'router_feature_deps'. I'm looking at you, nix...
extra_deps = []

# The very latest version of sanic (19.6.3 onwards) require websockets 7.x, but before
# that requires 6.x. Also, sanic dropped support for Python 3.5, leaving a long-term
# support version at 18.12. So stick to the older websockets for now, and pin sanic.
v = sys.version_info
assert v.major == 3
assert v.minor >= 5
sanic_fix = 'sanic==18.12.0' if v.minor == 5 else 'sanic==19.6.2'
websockets_fix = 'websockets>=6.0,<7.0'

with open('README.md', 'r') as f:
    long_description = f.read()

setup(name='entrance',
      version='1.1.7',
      author='Ensoft Ltd',
      description='Server framework for web apps',
      url='https://github.com/ensoft/entrance',

      long_description=long_description,
      long_description_content_type="text/markdown",
      packages=find_packages(),

      classifiers=[
        'Development Status :: 3 - Alpha',
        'Environment :: Web Environment',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7'
      ],

      install_requires=['pyyaml', sanic_fix, websockets_fix] + extra_deps,

      extras_require={
        'with-router-features': router_feature_deps
      }
)
