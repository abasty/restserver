#!/bin/sh

SHARED_DIR=$(realpath .)
PACKAGE_DIR=$(basename ${SHARED_DIR})

docker run --platform linux/arm/v7 \
    -v ${SHARED_DIR}:/root/${PACKAGE_DIR} \
    --name ${PACKAGE_DIR} \
    abasty/dart-armhf-qemu:2.13.4
