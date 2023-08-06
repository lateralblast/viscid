#!/usr/bin/env bash

# Name:         viscid (Visio Image Svg Convertor In Docker)
# Version:      0.0.6
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        Application
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Ubuntu Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script designed to use Docker to be able to run libvisio2svg on MacOS

SCRIPT_ARGS="$*"
START_PATH=$( pwd )

# Default variables

SCRIPT_NAME="viscid"
WORK_DIR="$START_PATH/files"
VERBOSE_MODE="false"
UBUNTU_VERSION="22.04"
GIT_URL="https://github.com/kakwa/libvisio2svg.git"

# Get the version of the script from the script itself

SCRIPT_VERSION=$( grep '^# Version' < "$0" | awk '{print $3}' )

print_help () {
  cat <<-HELP

  Usage: ${0##*/} [OPTIONS...]
    -c|--check    Check environment
    -h|--help     Help/Usage Information
    -i|--input    Input file
    -o|--output   Output file    
    -V|--version  Display Script Version
    -v|--verbose  Verbose mode
    -w|--workdir  Work Directory
HELP
  exit
}

# Handle output

handle_output () {
  OUTPUT_TEXT=$1
  if [ "$VERBOSE_MODE" = "true" ]; then
    echo "$OUTPUT_TEXT"
  fi
  return
}

# Check docker

check_docker () {
  handle_output "Information: Checking docker"
  DOCKER_TEST=$( which docker |grep -v found )
  if [[ ! "$DOCKER_TEST" =~ "docker" ]]; then
    VERBOSE_MODE="true"
    handle_output "Warning: docker not installed"
    exit
  else
    handle_output "Information: Found $DOCKER_TEST"
  fi
  handle_output "Information: Checking docker-compose"
  COMPOSE_TEST=$( which docker-compose |grep -v found )
  if [[ ! "$COMPOSE_TEST" =~ "docker" ]]; then
    VERBOSE_MODE="true"
    handle_output "Warning: docker-compose not installed"
    exit
  else
    handle_output "Information: Found $COMPOSE_TEST"
  fi
  return
}

# Create docker files
#
# Required libraries/commands:
#
# sudo apt install gsfonts libemf-dev libemf-doc libemf1 \
# libemf2svg-dev libemf2svg1 libuemf0 librevenge-0.0-0 \
# librevenge-dev libbrotli-dev libfreetype-dev libpng-dev \
# libpng-tools libwmf-0.2-7 libwmf-0.2-7-gtk libwmf-bin \
# libwmf-dev libwmf-doc libwmf0.2-7 libwmf0.2-7-gtk git \
# libvisio-0.1-1 libvisio-dev libvisio-doc libvisio-tools \
# cmake cmake-data dh-elpa-helper emacsen-common librhash0
# 
# git clone https://github.com/kakwa/libvisio2svg.git
# libvisio2svg 
# cmake . -DCMAKE_INSTALL_PREFIX=/usr/local 
# sudo make install

check_docker_files() {
  DOCKER_FILE="$WORK_DIR/Dockerfile"
  COMPOSE_FILE="$WORK_DIR/docker-compose.yml"
  if [ ! -f "$DOCKER_FILE" ]; then
    echo "FROM ubuntu:$UBUNTU_VERSION" > "$DOCKER_FILE"
    echo "RUN apt-get update && apt-get install -y gsfonts make cmake build-essential git libemf* libwmf* librevenge* libvisio* && git clone $GIT_URL && cd libvisio2svg && cmake . -DCMAKE_INSTALL_PREFIX=/usr/local && make install" >> "$DOCKER_FILE"
  fi
  if [ ! -f "$COMPOSE_FILE" ]; then
    echo "version: \"3\"" > "$COMPOSE_FILE"
    echo "" >> "$COMPOSE_FILE"
    echo "services:" >> "$COMPOSE_FILE"
    echo "  $SCRIPT_NAME:" >> "$COMPOSE_FILE"
    echo "    build:" >> "$COMPOSE_FILE"
    echo "      context: ." >> "$COMPOSE_FILE"
    echo "      dockerfile: Dockerfile" >> "$COMPOSE_FILE"
    echo "    image: $SCRIPT_NAME" >> "$COMPOSE_FILE"
    echo "    container_name: $SCRIPT_NAME" >> "$COMPOSE_FILE"
    echo "    entrypoint: /bin/bash" >> "$COMPOSE_FILE"
    echo "    working_dir: /root" >> "$COMPOSE_FILE"
    echo "" >> "$COMPOSE_FILE"
  fi
  return
}

# Create docker container

check_docker_container() {
  DOCKER_TEST=$( docker images |awk '{print $1}' |grep "$SCRIPT_NAME" )
  if [ ! "$DOCKER_TEST" ]; then 
    check_docker_files
    docker build "$WORK_DIR" --tag "$SCRIPT_NAME"
  fi
  return
}

# Check work dir

check_work_dir() {
  if [ ! -d "$WORK_DIR" ]; then
    mdkir -p "$WORK_DIR"
  fi
  return
}

# Check environment

check_environment() {
  check_work_dir
  check_docker_container
  return
}

# Check files

check_files() {
  if [ "$INPUT_FILE" ]; then
    INPUT_DIR=$( dirname "$INPUT_FILE" )
  fi
  if [ "$OUTPUT_FILE" = "" ]; then
    OUTPUT_FILE="$INPUT_FILE.svg"
  fi
  if [ "$OUTPUT_FILE" ]; then
    OUTPUT_DIR=$( dirname "$OUTPUT_FILE" )
  fi
  if [ ! -d "$INPUT_DIR" ]; then
    VERBOSE_MODE="true"
    handle_output "Warning: Input directory does not exist"
    exit
  fi
  if [ ! -f "$INPUT_FILE" ]; then
    VERBOSE_MODE="true"
    handle_output "Warning: Input file does not exist"
    exit
  fi
  if [ ! -d "$OUTPUT_DIR" ]; then
    VERBOSE_MODE="true"
    handle_output "Warning: Output directory does not exist"
    exit
  fi
  if [ -f "$OUTPUT_FILE" ]; then
    VERBOSE_MODE="true"
    handle_output "Warning: Output file already exists"
    exit
  fi
  handle_output "Input:  $INPUT_FILE"
  handle_output "Output: $INPUT_FILE"
  BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
  BASE_OUTPUT_FILE=$( basename "$OUTPUT_FILE" )
  DOCKER_INPUT_DIR="/root/input"
  DOCKER_OUTPUT_DIR="/root/output"
  DOCKER_INPUT_FILE="$DOCKER_INPUT_DIR/$BASE_INPUT_FILE"
  DOCKER_OUTPUT_FILE="$DOCKER_OUTPUT_DIR/$BASE_OUTPUT_FILE"
  return
}

# Run docker container

run_docker_container() {
  DOCKER_COMMAND="ldconfig ; /usr/local/bin/vss2svg-conv -i $DOCKER_INPUT_FILE -o $DOCKER_OUTPUT_FILE"
  handle_output "Executing: docker run --mount type=bind,source=\"$INPUT_DIR,target=$DOCKER_INPUT_DIR\" --mount type=bind,source=\"$OUTPUT_DIR,target=$DOCKER_OUTPUT_DIR\" $SCRIPT_NAME bash -c \"$DOCKER_COMMAND\""
  docker run --mount type=bind,source="$INPUT_DIR,target=$DOCKER_INPUT_DIR" --mount type=bind,source="$OUTPUT_DIR,target=$DOCKER_OUTPUT_DIR" $SCRIPT_NAME bash -c "$DOCKER_COMMAND"
  return
}

# Handle command line arguments

if [ "$SCRIPT_ARGS" = "" ]; then
  print_help
fi

while test $# -gt 0
do
  case $1 in
    -c|--check)
      check_environment
      shift
      ;;
    -h|--help)
      print_help
      ;;
    -i|--input)
      INPUT_FILE=$2
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE=$2
      shift 2
      ;;
    -V|--version)
      echo "$SCRIPT_VERSION"
      shift
      exit
      ;;
    -v|--verbose)
      VERBOSE_MODE="true"
      shift
      ;;
    -w|--workdir)
      WORK_DIR=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_help
      ;;
  esac
done

# Check environment

check_environment
check_files

run_docker_container
