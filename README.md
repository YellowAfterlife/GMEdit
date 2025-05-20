# GMEdit

GMEdit is a high-end, open-source code editor for GameMaker.

It represents what I consider to be the most important when working with code - being able to edit code quickly and comfortably, with features expected from a modern day code editor and conventional tabbed document design.

Rough lineup of features:

- Supports a variety of versions, including GameMaker: Studio, GameMaker Studio 2 (pre-2.3 and 2.3 formats), and limited support for legacy (GameMaker≤8.1) projects.  
  It can also be used to edit code for GML-based mods for games like [Nuclear Throne](https://yal.cc/ntt-modding-faq/) or [Rivals of Aether](https://rivalsofaether.com/introduction/).
- Spots a high-performance code editor ([Ace](https://ace.c9.io/)), extended and fine-tuned for GML.  
  Comes with [GameMaker-styled keyboard shortucts](http://github.com/GameMakerDiscord/GMEdit/wiki/Keyboard-shortcuts) that can be customized.
- Has combined editors for objects, timelines, and extensions, allowing to view/edit multiple events/moments/scripts at once.
- Fast save and load operations; only changes files it needs to.
- Has a variety of [syntax extensions](https://github.com/YellowAfterlife/GMEdit/wiki) to ease writing repetetive bits of code.  
  Changes are non-destructive and the code remains readable/editable in base IDE.
- Has custom [theme](https://github.com/YellowAfterlife/GMEdit/wiki/Using-themes)
  and [plugin](https://github.com/YellowAfterlife/GMEdit/wiki/Using-plugins) support.
- Free and open-source.

Overall, it can be viewed as a more pleasant alternative to GameMaker's base  IDE, and becomes increasingly more advantageous the more code you write or the more complex your code gets.

By design it is something that you run alongside the base IDE, but there are [ways](https://github.com/YellowAfterlife/GMEdit/wiki/Running-games-from-GMEdit) you can avoid switching back and forth to run the game.

**NEW!** [Try GMEdit online](https://yellowafterlife.github.io/GMEdit/)!  
This web-based version has some limitations compared to the downloadable one, but can give you a general idea of what GMEdit can do, and can also be used to open GameMaker projects without installing anything!

Maintained by: [YellowAfterlife](https://yal.cc)

## Pre-built binaries

Stable binaries can be found [on itch.io](https://yellowafterlife.itch.io/gmedit).

Same page also houses screenshots and development log.

## Building

### First time setup
1. Download/clone the repository.
2. Install a [current version of Haxe](https://haxe.org/download/).
3. Setup Electron by your preferred method:

   * Run `npm install`.
 
   * Download [a pre-built 33.x Electron binary](https://github.com/electron/electron/releases) and
     extract the files into `bin/` directory (so that you have `bin/electron.exe` on Windows or
     `bin/electron` on Mac/Linux). In `bin/resources/app`, run `npm install` to grab needed native
     packages.
 
   * Extract an existing GMEdit Beta to `bin/` without replacing files. This will also provide the
     extra non-MIT licensed components of GMEdit.
  
### Compiling
1. Build the project via
   ```
   haxe build.hxml
   ```
   or
   ```
   npm run compile
   ```
   or open and run the included FlashDevelop/HaxeDevelop project.

1. Run the compiled output with electron via `npm start` or just run the according Electron binary in
   `bin/`, if you chose this option.

### Credits

* Programming language: [Haxe](https://haxe.org)
* Code editor: [Ace](https://ace.c9.io/) (with custom plugins and some minor edits)
* Tab component: [Chrome tabs](https://github.com/adamschwartz/chrome-tabs) (moderately edited)
* Native wrapper: [Electron](https://electronjs.org/)
* Light theme tree icons: [Silk](http://www.famfamfam.com/lab/icons/silk/) (slightly edited)
* Dark theme tree icons: [Font Awesome](https://fontawesome.com/)
* zlib decompression: [pako](https://github.com/nodeca/pako)
* Windows title bar color detection: [this library](https://github.com/loilo/windows-titlebar-color)
* System font enumerator for the font editor: [font-scanner](https://www.npmjs.com/package/font-scanner) (slightly edited)

### License

[MIT license](https://opensource.org/licenses/mit-license.php)
