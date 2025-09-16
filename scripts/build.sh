#!/usr/bin/env bash

set -e
set -o pipefail
set -x
set -u

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"


source "$SCRIPTS_DIRECTORY/environment.sh"


# Remove the build directory if it exists to force a full rebuild.
if [ -d .build ] ; then
    rm -rf .build
fi

# Log the Swift version.
swift --version

# Run the tests.
swift test

# Build the project (debug and release).
swift build
swift build -c release
