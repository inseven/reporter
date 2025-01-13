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

## Schedule

```
0 3 * * * /home/jbmorley/bin/cronic-v3 /home/jbmorley/Projects/reporter/.build/debug/reporter
```

You might want to use something like [cronic](https://habilis.net/cronic/) to stop cron sending secondary emails.
