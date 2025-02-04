#!/usr/bin/env bash

set -e
set -o pipefail
set -x
set -u

export SWIFT_BIN=$PWD/swift-5.10-RELEASE-ubuntu22.04/usr/bin

if [ ! -d "$SWIFT_BIN" ] ; then
    curl -O https://download.swift.org/swift-5.10-release/ubuntu2204/swift-5.10-RELEASE/swift-5.10-RELEASE-ubuntu22.04.tar.gz
    tar -zxvf swift-5.10-RELEASE-ubuntu22.04.tar.gz
fi

export PATH=$PATH:$SWIFT_BIN

# Remove the build directory if it exists to force a full rebuild.
if [ -d .build ] ; then
    rm -rf .build
fi

# Run the tests.
# swift test

# Build the project.
swift build
