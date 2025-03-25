# How to use this

A description for you and also myself as updating Electron is not a frequent thing.

## Preparing to build

1. Grab base files from the [GitHub Actions build](https://github.com/YellowAfterlife/GMEdit/actions/workflows/build.yml).\
	If the artifacts have expired, you'll have to either ask me to re-run it or fork the repository so that you can run it yourself.
2. Each artifact is a ZIP with one or more ZIPs inside and you should extract these to `/export/base/`
	so that you have `/export/base/GMEdit-1.0.0-win.zip`, for example.

If you don't do this, you can still build AppOnly zips that go over regular GMEdit installs.

## Building the packager

(in `export/`)
```
haxe build.hxml
```

## Building

(in `export/bin/`)
```
neko Packager.n
```
Generated files go in `/export/out/`