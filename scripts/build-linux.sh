#!/usr/bin/env bash

# Copyright (c) 2024-2026 Jason Morley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail
set -x
set -u

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"
SWIFT_BUILD_DIRECTORY="$ROOT_DIRECTORY/.build"
ARTIFACTS_DIRECTORY="$BUILD_DIRECTORY/artifacts"


source "$SCRIPTS_DIRECTORY/environment.sh"

# Clean up and recreate the output directories.
if [ -d "$SWIFT_BUILD_DIRECTORY" ] ; then
    rm -rf "$SWIFT_BUILD_DIRECTORY"
fi
if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"
mkdir -p "$ARTIFACTS_DIRECTORY"

# Determine the version and build number.
# We expect these to be injected in by our GitHub build job so we just ensure there are sensible defaults.
VERSION_NUMBER=${VERSION_NUMBER:-0.0.0}
BUILD_NUMBER=${BUILD_NUMBER:-0}

# Log the Swift version.
swift --version

# Run the tests.
swift test

# Build the project (debug and release).
swift build -Xcc "-DVERSION_NUMBER=\"$VERSION_NUMBER\"" -Xcc "-DBUILD_NUMBER=\"$BUILD_NUMBER\""
swift build \
    -c release \
    -Xcc "-DVERSION_NUMBER=\"$VERSION_NUMBER\"" -Xcc "-DBUILD_NUMBER=\"$BUILD_NUMBER\"" \
    -Xswiftc -static-stdlib

# Ensure the commands have been created and can run.
"$SWIFT_BUILD_DIRECTORY/debug/reporter" --version
"$SWIFT_BUILD_DIRECTORY/release/reporter" --version

cd "$BUILD_DIRECTORY"

# Package.
source /etc/os-release
DISTRO=$ID
DESCRIPTION="File change report generator with built-in mailer."
URL="https://github.com/inseven/reporter"
MAINTAINER="Jason Morley <support@jbmorley.co.uk>"

case $DISTRO in
    ubuntu|debian)

        ARCHITECTURE=`dpkg --print-architecture`
        PACKAGE_FILENAME="reporter.deb"
        fpm \
            -s dir \
            -t deb \
            -p "$PACKAGE_FILENAME" \
            --name "reporter" \
            --version "${VERSION_NUMBER}~${VERSION_CODENAME}${BUILD_NUMBER}" \
            --architecture "$ARCHITECTURE" \
            --description "$DESCRIPTION" \
            --url "$URL" \
            --maintainer "$MAINTAINER" \
            --depends libssl3 \
            "$SWIFT_BUILD_DIRECTORY/release/reporter=/usr/bin/reporter"
        ;;

    *)
        fatal "Error: Unsupported distribution: $DISTRO."
        ;;
esac

# Copy the release binary to the artifacts directory.
cp "$PACKAGE_FILENAME" "$ARTIFACTS_DIRECTORY"
