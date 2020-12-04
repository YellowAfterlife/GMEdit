## GMEdit

This is an experimental open-source code editor for GameMaker: Studio / GameMaker Studio 2 projects.

The intent is to have a code editor that supports common features (syntax highlighting, auto-completion, object event editing) while providing a familiar multi-tab editor interface. Such thing would be convenient for any situations where you want project files to be updated in a timely manner when saving (e.g. [GMLive](https://yal.cc/introducing-gmlive-gml/)), but also for any large-scale projects where the whole popup window scheme doesn't really hold up anymore.

Maintained by: [YellowAfterlife](https://yal.cc)

### Setting up

* Download/clone the repository
* Download [a pre-built 7.x Electron binary](https://github.com/electron/electron/releases) and extract the files into bin/ directory (so that you have `bin/electron.exe` on Windows or `bin/electron` on Mac/Linux) (as of updating this README, 7.1.9 was used).
  
  Alternatively, extract an existing GMEdit Beta to `bin/` without replacing files.
* Build the project via  
  ```
  haxe build.hxml
  ```, ```
  npm run compile
  ```, or open and run the included FlashDevelop/HaxeDevelop project.

  You'll need the [latest release candidate version of Haxe 4](hhttps://haxe.org/download/version/4.0.0-rc.3/) - Haxe 3 will not work out of box due to API changes between the two.
* Run the compiled output with electron via `npm start` or just run the according Electron binary in bin/

### Pre-built binaries

Stable binaries can be found [on itch.io](https://yellowafterlife.itch.io/gmedit).

Same page also houses screenshots and development log.

### Credits

* Programming language: [Haxe](https://haxe.org)
* Code editor: [Ace](https://ace.c9.io/) (with custom plugins)
* Tab component: [Chrome tabs](https://github.com/adamschwartz/chrome-tabs) (moderately edited)
* Native wrapper: [Electron](https://electronjs.org/)
* Light theme tree icons: [Silk](http://www.famfamfam.com/lab/icons/silk/) (slightly edited)
* Dark theme tree icons: [Font Awesome](https://fontawesome.com/)
* zlib decompression: [pako](https://github.com/nodeca/pako)
* Windows title bar color detection: [this library](https://github.com/loilo/windows-titlebar-color)

### License

[MIT license](https://opensource.org/licenses/mit-license.php)
