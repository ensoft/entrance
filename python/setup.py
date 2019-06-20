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

import os
from setuptools import find_packages, setup

# Websockets v7 breaks sanic, so pin that dependency to prior release
websockets_fix = 'websockets==6.0'

# Router features require heavy dependencies, so include only when
# actually required, by setting the ENTRANCE_ROUTER_FEATURES
# environment variable
if 'ENTRANCE_ROUTER_FEATURES' in os.environ:
    router_deps = ['janus', 'ncclient', 'paramiko']
else:
    router_deps = []

with open('README.md', 'r') as f:
    long_description = f.read()

setup(name='entrance',
      version='1.1.4',
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

      install_requires=router_deps + \
          ['asyncio', 'pyyaml', 'sanic', websockets_fix]
)
