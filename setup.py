from setuptools import find_packages, setup

# Websockets v6 breaks sanic, so pin that dependency to last v5 release
# https://github.com/channelcat/sanic/issues/1264
websocket_fix = 'websockets==5.0.1'

with open('README.md', 'r') as f:
    long_description = f.read()

setup(name='entrance',
      version='0.0.5',
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
        'Programming Language :: Python :: 3.6'],

      install_requires=[
        'asyncio', 'janus', 'ncclient', 
        'paramiko', 'pyyaml', 'sanic', 
        websocket_fix]
)
