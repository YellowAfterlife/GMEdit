package gml;
import ace.extern.*;
import electron.FileSystem;
import electron.Electron;
import haxe.Json;
import haxe.io.Path;
import js.Boot;
import js.Error;
import js.RegExp;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
import raw.GmlLoader;
import tools.Dictionary;
import gml.GmlAPI;
import ace.AceWrap;
import gmx.*;
import yy.*;
import Main.window;
import Main.document;
import Main.moduleArgs;
import tools.HtmlTools;
import tools.NativeString;
import ui.ChromeTabs;
using tools.PathTools;
import gml.file.GmlFile;
import ui.GlobalSearch;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class Project {
	//
	public static var current(default, null):Project = null;
	//
	public static var nameNode = document.querySelector("#project-name");
	//
	public static var rxName:EReg = ~/^.+[\/\\](\w+)\.\w+$/g;
	//
	public var version:GmlVersion = GmlVersion.v1;
	
	/** full path */
	public var path:String;
	/** no directory */
	public var name:String;
	/** no directory, no extension */
	public var displayName:String;
	/** project directory */
	public var dir:String;
	/** whether this project is stored in memory rather than on disk */
	public var isVirtual:Bool;
	
	/** for room speed detection */
	public var gmxFirstRoomName:String = null;
	
	/** Object GUID -> object name */
	public var yyObjectNames:Dictionary<String>;
	/** Object name -> object GUID */
	public var yyObjectGUIDs:Dictionary<YyGUID>;
	/** Project GUID -> resource */
	public var yyResources:Dictionary<YyProjectResource>;
	/** Resource name -> GUID */
	public var yyResourceGUIDs:Dictionary<YyGUID>;
	/** GUID -> URL */
	public var yySpriteURLs:Dictionary<String>;
	
	/** name -> URL */
	public var spriteURLs:Dictionary<String> = new Dictionary();
	
	/** object name -> [...child names] */
	public var objectChildren:Dictionary<Array<String>>;
	//
	public var hasGMLive:Bool = false;
	
	/** whether X is a lambda script */
	public var lambdaMap:Dictionary<Bool> = new Dictionary();
	public var lambdaExt:String = null;
	public var lambdaGml:String = null;
	
	private var frameRate:Null<Int> = null;
	public function getFrameRate():Int {
		// Going to let this be synchronous as otherwise we might
		// fetch it several times in parallel while restoring tabs.
		var r = frameRate;
		if (r == null) switch (version) {
			case v1 if (gmxFirstRoomName != null): {
				try {
					var txt = readTextFileSync("rooms/" + gmxFirstRoomName + ".room.gmx");
					var rx = new RegExp("<speed>(\\d+)</speed>");
					var mt = rx.exec(txt);
					r = mt != null ? Std.parseInt(mt[1]) : 30;
				} catch (_:Dynamic) {
					r = 30;
				}
			};
			case v2: {
				try {
					var txt = readTextFileSync("options/main/inherited/options_main.inherited.yy");
					var rx = new RegExp('"option_game_speed": (\\d+)');
					var mt = rx.exec(txt);
					r = mt != null ? Std.parseInt(mt[1]) : 60;
				} catch (_:Dynamic) {
					r = 60;
				}
			};
			default: r = 30;
		}
		frameRate = r;
		return r;
	}
	//
	#if !lwedit
	private function new_procSingle() {
		var _path = path;
		inline function findV1(dir:String):Void {
			for (rel in FileSystem.readdirSync(dir)) {
				if (rel.ptExt() == "gmx" && rel.ptExt2() == "project") {
					path = dir.ptJoin(rel);
					break;
				}
			}
		}
		inline function findV2(dir:String):Void {
			for (rel in FileSystem.readdirSync(dir)) {
				if (rel.ptExt() == "yyp") {
					path = dir.ptJoin(rel);
					break;
				}
			}
		}
		inline function delayTab():Void {
			window.setTimeout(function() {
				var tabName = _path.ptNoDir();
				switch (tabName.ptExt()) {
					case "gmx": tabName = tabName.ptNoExt().ptNoExt();
					default: tabName = tabName.ptNoExt();
				}
				GmlFile.open(tabName, _path);
			}, 100);
		}
		if (Electron != null) switch (path.ptExt()) {
			case "gmx": switch (path.ptExt2()) {
				case "object", "extension": {
					version = GmlVersion.v1;
					path = null;
					findV1(_path.ptDir().ptDir());
					delayTab();
				};
			};
			case "yy": {
				version = GmlVersion.v2;
				path = null;
				findV2(_path.ptDir().ptDir().ptDir());
				delayTab();
			};
			case "gml": {
				var dir = path.ptDir(); // ".../some_yy/extensions/ext1"
				var dirName = dir.ptNoDir(); // "ext1"
				var outer:String = dir.ptDir(); // ".../some_yy/extensions"
				var outer2:String = outer.ptDir(); // ".../some_yy"
				version = GmlVersion.none;
				path = null;
				if (FileSystem.existsSync(dir.ptJoin(dirName + ".yy"))) { // ".../some/some.yy"
					version = GmlVersion.v2;
					findV2(outer2);
				}
				else if (dirName == "scripts") {
					findV1(outer);
					if (path != null) version = GmlVersion.v1;
				}
				else if (FileSystem.existsSync(dir + ".extension.gmx")) {
					version = v1;
					findV1(outer2);
				}
				if (version == GmlVersion.none) {
					version = GmlVersion.detect(FileSystem.readTextFileSync(_path));
					if (version == GmlVersion.none) version = v2;
				}
				delayTab();
			};
		}
	}
	#end
	public function new(_path:String) {
		path = _path;
		#if !lwedit
		new_procSingle();
		#end
		if (path != null) {
			dir = path.ptDir();
			name = path.ptNoDir();
		} else {
			dir = _path.ptDir();
			name = _path.ptNoDir();
			displayName = name;
		}
		#if !lwedit
		if (path != null) detectVersion();
		document.title = name != "" ? (name + " - GMEdit") : "GMEdit";
		TreeView.clear();
		reload(true);
		#else
		version = GmlVersion.v1;
		GmlAPI.version = version;
		#end
	}
	public function detectVersion() {
		if (path == "") {
			name = "";
			version = GmlVersion.none;
			displayName = "Recent projects";
		} else {
			version = path.ptDetectProject();
			switch (version) {
				case GmlVersion.v2: {
					displayName = name.ptNoExt();
				};
				case GmlVersion.v1: {
					displayName = name.ptNoExt().ptNoExt();
				};
				case GmlVersion.live: {
					name = dir.ptNoDir();
					displayName = name;
				};
				default: displayName = name;
			}
		}
	}
	public static function open(path:String) {
		if (current != null) current.close();
		current = new Project(path);
		if (path != "") ui.RecentProjects.add(current.path != null ? current.path : path);
	}
	public function close() {
		TreeView.saveOpen();
		var tabPaths:Array<String> = [];
		for (_tab in ChromeTabs.element.querySelectorAll(".chrome-tab")) try {
			var tab:ChromeTab = cast _tab;
			var path = tab.gmlFile.path;
			if (path != null) tabPaths.push(path);
		} catch (_:Dynamic) { }
		var data:ProjectState = {
			treeviewScrollTop: TreeView.element.scrollTop,
			treeviewOpenNodes: TreeView.openPaths,
			tabPaths: tabPaths,
		};
		window.localStorage.setItem("project:" + path, Json.stringify(data));
		window.localStorage.setItem("@project:" + path, "" + Date.now().getTime());
	}
	public var firstLoadTabPaths:Array<String> = null;
	public function finishedIndexing() {
		nameNode.innerText = displayName;
		if (current.hasGMLive) ui.GMLive.updateAll();
		// try restoring tabs:
		var tabPaths = firstLoadTabPaths;
		if (tabPaths != null) {
			firstLoadTabPaths = null;
			for (path in tabPaths) try {
				var el = TreeView.find(true, { path: path });
				if (el != null) TreeView.handleItemClick(null, el);
			} catch (x:Dynamic) {
				Main.console.error("Error recovering " + path + ":", x);
			}
		}
	}
	//
	public static function init() {
		//
		var ls = window.localStorage;
		var renList:Array<String> = [];
		var remList:Array<String> = [];
		var remTime:Float = Date.now().getTime()
			- (1000 * 60 * 60 * 24 * ui.Preferences.current.projectSessionTime);
		for (i in 0 ... ls.length) {
			var k = ls.key(i);
			if (NativeString.startsWith(k, "@project:")) {
				if (k.indexOf("\x5c") >= 0) {
					renList.push(k);
				}
				else if (Std.parseFloat(ls.getItem(k)) < remTime) {
					remList.push(k);
					remList.push(k.substring(1));
				}
			}
		}
		for (remKey in remList) ls.removeItem(remKey);
		for (renKey in renList) {
			var renKey1 = renKey.substring(1);
			var v0 = ls.getItem(renKey);
			var v1 = ls.getItem(renKey1);
			ls.removeItem(renKey);
			ls.removeItem(renKey1);
			ls.setItem(renKey.ptNoBS(), v0);
			ls.setItem(renKey1.ptNoBS(), v1);
		}
		//
		#if !lwedit
		var path = moduleArgs["open"];
		if (path != null) {
			open(path.ptNoBS());
		} else open("");
		#else
		current = new YyZip("", "", []);
		#end
	}
	//
	public function reload(?first:Bool) {
		nameNode.innerText = "Loading...";
		window.setTimeout(function() {
			objectChildren = new Dictionary();
			GmlAPI.version = version;
			var state:ProjectState = null;
			if (first) {
				GmlSeekData.map = new Dictionary();
				try {
					var stateText = window.localStorage.getItem("project:" + path);
					state = Json.parse(stateText);
				} catch (_:Dynamic) { }
			} else TreeView.saveOpen();
			reload_1();
			ace.AceTooltips.resetCache();
			TreeView.restoreOpen(state != null ? state.treeviewOpenNodes : null);
			if (state != null) {
				TreeView.element.scrollTop = state.treeviewScrollTop;
				if (first) {
					firstLoadTabPaths = state.tabPaths;
				}
			}
			if (GmlSeeker.itemsLeft == 0) {
				nameNode.innerText = displayName;
			} else nameNode.innerText = "Indexing...";
			ui.ProjectStyle.reload();
		}, 1);
	}
	private function reload_1() {
		if (version == GmlVersion.none) {
			ui.RecentProjects.show();
		} else if (path == null) {
			TreeView.clear();
		} else switch (version) {
			case GmlVersion.v1: GmxLoader.run(this);
			case GmlVersion.v2: YyLoader.run(this);
			case GmlVersion.live: GmlLoader.run(this);
			default:
		}
	}
	//
	/** fn(name, path, code), */
	public function search(fn:ProjectSearcher, done:Void->Void, ?opt:GlobalSearchOpt) {
		switch (version) {
			case GmlVersion.v1: GmxSearcher.run(this, fn, done, opt);
			case GmlVersion.v2: YySearcher.run(this, fn, done, opt);
			default:
		}
	}
	//
	public function fullPath(path:String) {
		if (dir != "") {
			return (dir + "/" + path).ptNoBS();
		} else return path;
	}
	public function existsSync(path:String):Bool {
		return FileSystem.existsSync(fullPath(path));
	}
	public function unlinkSync(path:String):Void {
		FileSystem.unlinkSync(fullPath(path));
	}
	public function readTextFile(path:String, fn:Error->String->Void):Void {
		FileSystem.readTextFile(fullPath(path), fn);
	}
	public function readTextFileSync(path:String):String {
		return FileSystem.readTextFileSync(fullPath(path));
	}
	public function readJsonFile<T:{}>(path:String, fn:Error->T->Void):Void {
		FileSystem.readJsonFile(fullPath(path), fn);
	}
	public function readJsonFileSync<T>(path:String):T {
		return FileSystem.readJsonFileSync(fullPath(path));
	}
	public function readGmxFile(path:String, fn:Error->SfGmx->Void):Void {
		return FileSystem.readGmxFile(fullPath(path), fn);
	}
	public function readGmxFileSync(path:String):SfGmx {
		return FileSystem.readGmxFileSync(fullPath(path));
	}
	public function writeTextFileSync(path:String, text:String) {
		FileSystem.writeFileSync(fullPath(path), text);
	}
	public inline function writeJsonFileSync(path:String, value:Dynamic) {
		writeTextFileSync(path, NativeString.yyJson(value));
	}
	public function renameSync(prev:String, next:String) {
		if (existsSync(prev)) {
			FileSystem.renameSync(fullPath(prev), fullPath(next));
		}
	}
	/**
	 * Gets a URL for given relative path that could be used in CSS.
	 * This can be either a file:/// or a data URL
	 */
	public function getImageURL(path:String):String {
		var full = fullPath(path);
		return FileSystem.existsSync(full) ? ("file:///" + full) : null;
	}
	/**
	 * Like getImageURL but takes a sprite name and gets you a URL for it's first frame
	 * Generally used for thumbnails.
	 */
	public function getSpriteURL(name:String):String {
		if (version == GmlVersion.live) return null;
		if (spriteURLs.exists(name)) {
			return spriteURLs[name];
		}
		var r:String;
		switch (version) {
			case v1: r = getImageURL("sprites/images/" + name + "_0.png");
			case v2: {
				var g:YyGUID = yyResourceGUIDs[name];
				if (g != null) {
					if (yySpriteURLs.exists(g)) {
						r = yySpriteURLs[g];
					} else try {
						var spritePath = yyResources[g].Value.resourcePath;
						var sprite:YySprite = readJsonFileSync(spritePath);
						var frame = sprite.frames[0];
						if (frame != null) {
							var framePath = Path.join([Path.directory(spritePath), frame.id + ".png"]);
							r = getImageURL(framePath);
						} else r = null;
						yySpriteURLs.set(g, r);
					} catch (e:Dynamic) {
						r = null;
					}
				} else r = null;
			};
			default: r = null;
		}
		spriteURLs.set(name, r);
		return r;
	}
	public function getSpriteURLasync(name:String, fn:String->Void):Void {
		if (version == GmlVersion.live) return;
		function soon_1(fn:String->Void, s:String):Void {
			window.setTimeout(function() fn(s));
		}
		inline function soon(s:String):Void {
			spriteURLs.set(name, s);
			soon_1(fn, s);
		}
		inline function now(s:String):Void {
			spriteURLs.set(name, s); fn(s);
		}
		if (spriteURLs.exists(name)) {
			soon(spriteURLs[name]);
			return;
		}
		switch (version) {
			case v1: {
				var full = fullPath("sprites/images/" + name + "_0.png");
				FileSystem.access(full, FileSystemAccess.Exists, function(e) {
					full = e == null ? "file:///" + full : null;
					now(full);
				});
			}
			case v2: {
				var g:YyGUID = yyResourceGUIDs[name];
				if (g != null) {
					if (yySpriteURLs.exists(g)) {
						soon(yySpriteURLs[g]);
					} else {
						var spritePath = yyResources[g].Value.resourcePath;
						readJsonFile(spritePath, function(e, sprite:YySprite) {
							var r:String;
							if (e == null) {
								var frame = sprite.frames[0];
								if (frame != null) {
									var framePath = Path.join([Path.directory(spritePath), frame.id + ".png"]);
									r = getImageURL(framePath);
								} else r = null;
							} else r = null;
							yySpriteURLs.set(g, r);
							now(r);
						});
					}
				} else soon(null);
			};
			default: soon(null);
		}
	}
	//
	public function mkdirSync(path:String) {
		var full = fullPath(path);
		if (!FileSystem.existsSync(full)) {
			FileSystem.mkdirSync(full);
		}
	}
	public function rmdirSync(path:String) {
		var full = fullPath(path);
		if (FileSystem.existsSync(full)) {
			FileSystem.rmdirSync(full);
		}
	}
	public function readdir(path:String, fn:Error->Array<ProjectDirInfo>->Void):Void {
		FileSystem.readdir(path, function(e, rels) {
			var found:Array<ProjectDirInfo>;
			if (rels != null) {
				var full = fullPath(path);
				found = [];
				for (rel in rels) {
					var itemFull = Path.join([full, rel]);
					found.push({
						fileName: rel,
						isDirectory: FileSystem.statSync(itemFull).isDirectory()
					});
				}
			} else found = null;
			fn(e, found);
		});
	}
	public function readdirSync(path:String):Array<ProjectDirInfo> {
		var full = fullPath(path);
		var out:Array<ProjectDirInfo> = [];
		for (rel in FileSystem.readdirSync(full)) {
			var itemFull = Path.join([full, rel]);
			out.push({
				fileName: rel,
				isDirectory: FileSystem.statSync(itemFull).isDirectory()
			});
		}
		return out;
	}
	//
	public function openExternal(path:String) {
		electron.Shell.openItem(fullPath(path));
	}
	public function showItemInFolder(path:String) {
		electron.Shell.showItemInFolder(fullPath(path));
	}
	//
}
/** (name, path, code) */
typedef ProjectSearcher = String->String->String->Null<String>;
typedef ProjectState = {
	treeviewScrollTop:Int,
	treeviewOpenNodes:Array<String>,
	tabPaths:Array<String>,
}
typedef ProjectDirInfo = {
	fileName:String,
	isDirectory:Bool,
}
