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

```
{
    "mailServer": {

        "host": "smtp.example.org",
        "port": 587,
         "username": "email",
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

```
0 3 * * * /home/jbmorley/bin/cronic-v3 /home/jbmorley/Projects/reporter/.build/debug/reporter
```

You might want to use something like [cronic](https://habilis.net/cronic/) to stop cron sending secondary emails.
