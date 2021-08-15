#!/bin/sh

EXE_FILE="coursesd"
SRC_FILE="bin/courses_server.dart"

SHARED_DIR=$(realpath .)
PACKAGE_DIR=$(basename ${SHARED_DIR})

dart compile exe -o ${EXE_FILE} -S /tmp/symbols ${SRC_FILE}
