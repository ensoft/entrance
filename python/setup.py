from setuptools import find_packages, setup

# Websockets v7 breaks sanic, so pin that dependency to prior release
websockets_fix = 'websockets==6.0'

with open('README.md', 'r') as f:
    long_description = f.read()

setup(name='entrance',
      version='1.0.1',
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

      install_requires=[
        # Required for core functionality
        'asyncio', 'pyyaml', 'sanic', websockets_fix,

        # Required only for the built-in features for talking
        # to routers - should probably split out somehow
        'janus', 'ncclient','paramiko'
      ]
)
