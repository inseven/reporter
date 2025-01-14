# Reporter

File change monitor for macOS and Linux with built-in mailer

## Overview

Reporter is a lightweight command line utility that generates email reports showing all file system changes since the last run. It is intended to pair with self-hosted file shares and network attached storage to improve visibility of file changes with minimum cognitive overhead.

Most other change detection tools I've been able to find appear to be focused on integrity checks or more complaince-focused auditing. Conversely, my goal with Reporter is to create something that's easy to configure and offers more consumer-style reports—the sort of thing you might get from Dropbox or other centralized file sync services.

_This is currently in active development so your mileage may vary, but I'd love your feedback and input if you try it out and find it useful._

## Installation

There are currently no pre-built releases of Reporter. Check out the [Development](#development) section for details of how to build and run it yourself.

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

        "from": "server@example.org",
        "to": "admin@example.org",
    },

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
0 3 * * * /home/jbmorley/Projects/reporter/.build/debug/reporter
```

N.B. Depending on your server's mail configuration, you might want to use something like [cronic](https://habilis.net/cronic/) to quiet the output and stop `cron` sending mails unless there's an error.


## Development

### Dependencies

Reporter is written in Swift. You can use tools like [`swiftenv`](https://swiftenv.fuller.li/en/latest/) and [mise-en-place](https://mise.jdx.dev) to manage the Swift toolchain on Linux and macOS.

### Build

```shell
git clone git@github.com:inseven/reporter.git
cd reporter
swift build
./.build/debug/reporter
```

### Run

```shell
swift run
```
