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
ARTIFACTS_DIRECTORY="$ROOT_DIRECTORY/artifacts"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"
TEMPORARY_DIRECTORY="$ROOT_DIRECTORY/temp"

ENV_PATH="$ROOT_DIRECTORY/.env"
RELEASE_SCRIPT_PATH="$SCRIPTS_DIRECTORY/upload-and-publish-release.sh"

source "$SCRIPTS_DIRECTORY/environment.sh"

# Check that the GitHub command is available on the path.
which gh || (echo "GitHub cli (gh) not available on the path." && exit 1)

# Process the command line arguments.
POSITIONAL=()
RELEASE=${RELEASE:-false}
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -r|--release)
        RELEASE=true
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

# Source the .env file if it exists to make local development easier.
if [ -f "$ENV_PATH" ] ; then
    echo "Sourcing .env..."
    source "$ENV_PATH"
fi

cd "$ROOT_DIRECTORY"

# Clean up and recreate the output directories.
if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

# List the artifacts.
find "$ARTIFACTS_DIRECTORY"

# Copy the artifacts to the builds directory, adding each to the manifest.

cd "$BUILD_DIRECTORY"

GIT_SHA=`git rev-parse HEAD`

REPORTER_MACOS_NAME="reporter-$VERSION_NUMBER-$BUILD_NUMBER.zip"
cp "$ARTIFACTS_DIRECTORY/reporter-macos/reporter.zip" "$REPORTER_MACOS_NAME"

build-tools add-artifact manifest.json \
    --project reporter \
    --version "$VERSION_NUMBER" \
    --build-number "$BUILD_NUMBER" \
    --path "$REPORTER_MACOS_NAME" \
    --format zip \
    --git-sha "$GIT_SHA" \
    --supports-os macos \
    --supports-version 26 \
    --supports-codename tahoe \
    --supports-architecture arm64 \
    --supports-architecture x86_64

REPORTER_UBUNTU_NAME="reporter_${VERSION_NUMBER}_${BUILD_NUMBER}_ubuntu_noble_amd64.deb"
cp "$ARTIFACTS_DIRECTORY/reporter-linux/reporter.deb" "$REPORTER_UBUNTU_NAME"

build-tools add-artifact manifest.json \
    --project reporter \
    --version "$VERSION_NUMBER" \
    --build-number "$BUILD_NUMBER" \
    --path "$REPORTER_UBUNTU_NAME" \
    --format deb \
    --git-sha "$GIT_SHA" \
    --supports-os ubuntu \
    --supports-version 24.04 \
    --supports-codename noble \
    --supports-architecture amd64

if $RELEASE ; then

    changes \
        release \
        --skip-if-empty \
        --push \
        --exec "$RELEASE_SCRIPT_PATH" \
        "$BUILD_DIRECTORY/$REPORTER_MACOS_NAME" \
        "$BUILD_DIRECTORY/$REPORTER_UBUNTU_NAME" \
        "$BUILD_DIRECTORY/manifest.json"

fi
