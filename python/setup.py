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
router_feature_deps = ["janus", "ncclient", "paramiko"]

# Acutally, an icky second way of including the optional dependencies would just be
# to rewrite this from '[]' to 'router_feature_deps'. I'm looking at you, nix...
extra_deps = []

with open("README.md", "r") as f:
    long_description = f.read()

setup(
    name="entrance",
    version="1.2.0",
    author="Ensoft Ltd",
    description="Server framework for web apps",
    url="https://github.com/ensoft/entrance",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: Web Environment",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
    ],
    install_requires=["pyyaml", "uvicorn", "fastapi", "ujson", "websockets"] + extra_deps,
    extras_require={"with-router-features": router_feature_deps},
)
