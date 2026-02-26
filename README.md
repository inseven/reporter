# Reporter

[![build](https://github.com/inseven/reporter/actions/workflows/build.yaml/badge.svg)](https://github.com/inseven/reporter/actions/workflows/build.yaml)

File change report generator for macOS and Linux a with built-in mailer

## Overview

Reporter is a lightweight command line utility that generates email reports showing all file system changes since the last run. It is intended to pair with self-hosted file shares and network attached storage to improve visibility of file changes with minimum cognitive overhead.

Most other change detection tools I've been able to find appear to be focused on integrity checks or more complaince-focused auditing. Conversely, my goal with Reporter is to create something that's easy to configure and offers more consumer-style reports—the sort of thing you might get from Dropbox or other centralized file sync services.

_This is currently in active development so your mileage may vary, but I'd love your feedback and input if you try it out and find it useful._

## Installation

There are currently pre-built binaries for macOS, and for amd64 and arm64 builds of Ubuntu, releases 24.04 (Noble Numbat) and 25.10 (Questing Quokka).

### Ubuntu

```sh
curl -fsSL https://releases.jbmorley.co.uk/apt/public.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/jbmorley.gpg
echo "deb https://releases.jbmorley.co.uk/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/jbmorley.list
sudo apt update
sudo apt install reporter
```

### macOS

Download the [latest release](https://github.com/inseven/reporter/releases/latest).

## Configuration

Settings are stored in `~/.config/reporter/config.json`. Mine looks something like this:

```json
{
    "mailServer": {

        "host": "smtp.example.org",
        "port": 587,
        "username": "username",
        "password": "password",

        "domain": "server.example.org",
        "timeout": 30,

    },

    "email": {

        "from": {
            "address": "server@example.org",
            "name": "My Server"
        },

        "to": [
            {
                "address": "admin@example.org",
                "name": "Example.org Admin"
            }
        ]

    }

    "folders": {
        "/mnt/usb0/Storage/Audiobooks": {},
        "/mnt/usb0/Storage/Books": {},
        "/mnt/usb0/Storage/Downloads": {},
        "/mnt/usb0/Storage/Magazines": {},
        "/mnt/usb0/Storage/Manuals": {},
        "/mnt/usb0/Storage/Notes": {},
        "/mnt/usb0/Storage/Paperwork": {},
        "/mnt/usb0/Storage/Pictures": {},
        "/mnt/usb0/Storage/Software": {}
    }

}
```

## Schedule

Reporter does not currently provide built-in support for scheduling checks, instead deferring to external task runners like [`cron`](https://en.wikipedia.org/wiki/Cron).

For example, my current configuration uses `cron` to schedule builds at 3am every morning:

```plaintext
0 3 * * * /home/jbmorley/Projects/reporter/.build/release/reporter scan
```

N.B. Depending on your server's mail configuration, you might want to use something like [cronic](https://habilis.net/cronic/) to quiet the output and stop `cron` sending mails unless there's an error.


## Development

### Dependencies

Reporter is written in Swift. [Swiftly](https://www.swift.org/install/) is the recommended mechanism to install the Swift toolchain.

```shell
git clone git@github.com:inseven/reporter.git
cd reporter
git submodule update --init --recursive
mise install
```

#### Debian

```shell
sudo apt-get install libssl-dev
```

### Build

```shell
scripts/build.sh
```

Under the hood, this runs `swift test`, `swift build`, and `swift build -c release`.

### Run

Use the `swift` compiler:

```shell
swift run reporter scan
```

Or run the result of `build.sh` (above) directly:

```shell
.build/release/reporter scan
```
