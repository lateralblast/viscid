![Viscid cat](https://raw.githubusercontent.com/lateralblast/viscid/master/viscid.png)

VISCID
------

Visio Image SVG Convertor In Docker

Version
-------

Current Version: 0.0.6

Introduction
------------

libvisio2svg cannot be compiled reliably on MacOS, especially on ARM, so this script uses a Linux docker container
to do the conversion.

If only the input file is specified, the script with create an output file with the input file name and add a .svg extension

The script with use the input and output file directories as loop back mounts.

If the Docker container does not exist the script with create the relevant files and create the container.

Examples
--------

Convert Visio file to SVG:

```
./viscid.sh --input ./Purestorage.vss
```

Usage information:

```
./viscid.sh --help

  Usage: viscid.sh [OPTIONS...]
    -c|--check    Check environment
    -h|--help     Help/Usage Information
    -i|--input    Input file
    -o|--output   Output file
    -V|--version  Display Script Version
    -v|--verbose  Verbose mode
    -w|--workdir  Work Directory
```

Prerequisites
-------------

MacOS:

- docker
- docker-compose

Linux Docker Container:

- build-essential
- make
- cmake
- cmake-data
- dh-elpa-helper
- emacsen-common
- librhash0
- git
- gsfonts
- libemf-dev
- libemf-doc
- libemf1
- libemf2svg-dev
- libemf2svg1
- libuemf0
- librevenge-0.0-0
- librevenge-dev
- libbrotli-dev
- libfreetype-dev
- libpng-dev
- libpng-tools
- libwmf-0.2-7
- libwmf-0.2-7-gtk
- libwmf-bin
- libwmf-dev
- libwmf-doc
- libwmf0.2-7
- libwmf0.2-7-gtk
- libvisio-0.1-1
- libvisio-dev
- libvisio-doc
- libvisio-tools

Docker
------

The script generates a Docker file like this if it doesn't exist:

```
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y gsfonts make cmake build-essential git libemf* libwmf* librevenge* libvisio* && git clone https://github.com/kakwa/libvisio2svg.git && cd libvisio2svg && cmake . -DCMAKE_INSTALL_PREFIX=/usr/local && make install
```

The script creates a compose file like this if it doesn't exist:

```
version: "3"

services:
  viscid:
    build:
      context: .
      dockerfile: Dockerfile
    image: viscid
    container_name: viscid
    entrypoint: /bin/bash
    working_dir: /root
```

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

