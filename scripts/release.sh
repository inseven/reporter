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

# Copy the artifacts to the builds directory.

REPORTER_MACOS_PATH="$BUILD_DIRECTORY/reporter-$VERSION_NUMBER-$BUILD_NUMBER.zip"
cp "$ARTIFACTS_DIRECTORY/reporter-macos/reporter.zip" "$REPORTER_MACOS_PATH"

REPORTER_UBUNTU_PATH="$BUILD_DIRECTORY/reporter_${VERSION_NUMBER}_${BUILD_NUMBER}_ubuntu_noble_amd64.zip"
cp "$ARTIFACTS_DIRECTORY/reporter-linux/reporter.deb" "$REPORTER_UBUNTU_PATH"

# if $RELEASE ; then
#
#     changes \
#         release \
#         --skip-if-empty \
#         --push \
#         --exec "$RELEASE_SCRIPT_PATH" \
#         "$IPA_PATH" "$PKG_PATH" \
#         "$QT_MACOS_PATH" \
#         "$QT_WINDOWS_PATH" \
#         "$QT_UBUNTU_2404_ARM64_PATH" "$QT_UBUNTU_2404_AMD64_PATH" \
#         "$QT_UBUNTU_2504_ARM64_PATH" "$QT_UBUNTU_2504_AMD64_PATH" \
#         "$QT_UBUNTU_2510_ARM64_PATH" "$QT_UBUNTU_2510_AMD64_PATH" \
#         "$QT_ARCH_ROLLING_X86_64_PATH"
#
# fi
