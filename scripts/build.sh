#!/usr/bin/env bash

set -e
set -o pipefail
set -x
set -u

# Remove the build directory if it exists to force a full rebuild.
if [ -d .build ] ; then
    rm -rf .build
fi

# Run the tests.
swift test

# Build the project (debug and release).
swift build
swift build -c release
