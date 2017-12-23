## What's this

This is an experimental open-source code editor for GameMaker: Studio projects.

The intent is to have a code editor that supports common features (syntax highlighting, auto-completion, object event editing) while providing a familiar multi-tab editor interface. Such thing would be convenient for any situations where you want project files to be updated in a timely manner when saving (e.g. [GMLive](https://yal.cc/introducing-gmlive-gml/)), but also for any large-scale projects where the whole popup window scheme doesn't really hold up anymore.

### Setting up

* Download/clone the repository
* Download [a pre-built Electron binary](https://github.com/electron/electron/releases) and extract the files into bin/ directory (so that you have `bin/electron.exe`).
* Build the project via `haxe -cp src -js ./bin/resources/app/app.js -D nodejs -main Main -dce full` (or open and run the included FlashDevelop project)

### Credits

* Programming language: [Haxe](https://haxe.org)
* Code editor: [Ace](https://ace.c9.io/)
* [Chrome tabs](https://github.com/adamschwartz/chrome-tabs)
* Native wrapper: [Electron](https://electronjs.org/)
* Light theme tree icons (slightly edited): [Silk](http://www.famfamfam.com/lab/icons/silk/)
* Dark theme tree icons: [Font Awesome](https://fontawesome.com/)

### License

[MIT license](https://opensource.org/licenses/mit-license.php)
