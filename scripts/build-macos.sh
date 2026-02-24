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
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"
SWIFT_BUILD_DIRECTORY="$ROOT_DIRECTORY/.build"
TEMPORARY_DIRECTORY="$ROOT_DIRECTORY/temp"

ARCHIVE_PATH="$BUILD_DIRECTORY/Reporter.xcarchive"
ENV_PATH="$ROOT_DIRECTORY/.env"
KEYCHAIN_PATH="$TEMPORARY_DIRECTORY/temporary.keychain"

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

# Generate a random string to secure the local keychain.
export TEMPORARY_KEYCHAIN_PASSWORD=`openssl rand -base64 14`

# Source the .env file if it exists to make local development easier.
if [ -f "$ENV_PATH" ] ; then
    echo "Sourcing .env..."
    source "$ENV_PATH"
fi

cd "$ROOT_DIRECTORY"

# Select the correct Xcode.
sudo xcode-select --switch "$MACOS_XCODE_PATH"

# Clean up and recreate the output directories.

if [ -d "$SWIFT_BUILD_DIRECTORY" ] ; then
    rm -rf "$SWIFT_BUILD_DIRECTORY"
fi

if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

# Create the a new keychain.
if [ -d "$TEMPORARY_DIRECTORY" ] ; then
    rm -rf "$TEMPORARY_DIRECTORY"
fi
mkdir -p "$TEMPORARY_DIRECTORY"
echo "$TEMPORARY_KEYCHAIN_PASSWORD" | build-tools create-keychain "$KEYCHAIN_PATH" --password

function cleanup {

    # Cleanup the temporary files, keychain and keys.
    cd "$ROOT_DIRECTORY"
    build-tools delete-keychain "$KEYCHAIN_PATH"
    rm -rf "$TEMPORARY_DIRECTORY"
    rm -rf ~/.appstoreconnect/private_keys
}

trap cleanup EXIT

# Log the Swift version.
swift --version

# Determine the version and build number.
# We expect these to be injected in by our GitHub build job so we just ensure there are sensible defaults.
VERSION_NUMBER=${VERSION_NUMBER:-0.0.0}
BUILD_NUMBER=${BUILD_NUMBER:-0}

# Run the tests.
swift test

# Build the project (debug and release).
# We do this as part of the macOS builds (as well as the Linux builds) even though it's not strictly necessary to ensure
# we've not broken the ability to build and run without Xcode.
swift build -Xcc "-DVERSION_NUMBER=\"$VERSION_NUMBER\"" -Xcc "-DBUILD_NUMBER=\"$BUILD_NUMBER\""
swift build -c release -Xcc "-DVERSION_NUMBER=\"$VERSION_NUMBER\"" -Xcc "-DBUILD_NUMBER=\"$BUILD_NUMBER\""

# Ensure the commands have been created and can run.
"$SWIFT_BUILD_DIRECTORY/debug/reporter" --version
"$SWIFT_BUILD_DIRECTORY/release/reporter" --version

# Import the certificates into our dedicated keychain.
echo "$DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD" | build-tools import-base64-certificate --password "$KEYCHAIN_PATH" "$DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64"

pushd Reporter

# Build and archive the command (using Xcode).
# We pass the build number and version in two different ways for the Xcode project and Swift package respectively.
xcodebuild \
    -project Reporter.xcodeproj \
    -scheme "reporter" \
    -archivePath "$ARCHIVE_PATH" \
    OTHER_CODE_SIGN_FLAGS="--keychain=\"${KEYCHAIN_PATH}\"" \
    MARKETING_VERSION=$VERSION_NUMBER \
    CURRENT_PROJECT_VERSION=$BUILD_NUMBER \
    GCC_PREPROCESSOR_DEFINITIONS="\$inherited VERSION_NUMBER=\\\"$VERSION_NUMBER\\\" BUILD_NUMBER=\\\"$BUILD_NUMBER\\\"" \
    clean archive

# N.B. We do not currently attempt to export this archive as it's apparently a 'generic' archive that xcodebuild doesn't
# know what to do with. Instead, we pluck our binary directly out of the archive as we know where it is and we're going
# to package it and notarize it ourselves.
cp "$ARCHIVE_PATH/Products/usr/local/bin/reporter" "$BUILD_DIRECTORY/reporter"

# Notarization.

API_KEY_PATH="$TEMPORARY_DIRECTORY/api.key"
echo "$APPLE_API_KEY_BASE64" | base64 -d > "$API_KEY_PATH"

# Notarize the command.
build-tools notarize "$BUILD_DIRECTORY/reporter" \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    --skip-staple

# Package up the build.
cd "$BUILD_DIRECTORY"
zip --symlinks -r "build.zip" "reporter"
