#!/bin/sh

SHARED_DIR=$(realpath .)
PACKAGE_DIR=$(basename ${SHARED_DIR})

docker start ${PACKAGE_DIR}
docker attach ${PACKAGE_DIR}
