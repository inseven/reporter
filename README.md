# Reporter

## Dependencies

[mise-en-place](https://mise.jdx.dev) is a great tool for managing the Swift toolchain, especially on Linux:

```
curl https://mise.run | sh
mise install swift
```

## Build

```
git clone git@github.com:inseven/reporter.git
cd reporter
swift build
./.build/debug/reporter
```

## Configuration

Settings are stored in `~/.config/reporter/config`. Mine looks something like this:

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
