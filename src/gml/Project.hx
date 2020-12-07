package gml;
import ace.extern.*;
import electron.FileSystem;
import electron.Electron;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Path;
import js.Boot;
import js.lib.Error;
import js.lib.RegExp;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
import tools.Dictionary;
import tools.Aliases;
import gml.GmlAPI;
import plugins.PluginEvents;
import plugins.PluginManager;
import ace.AceWrap;
import gmk.*;
import gmx.*;
import raw.*;
import yy.*;
import Main.window;
import Main.document;
import Main.moduleArgs;
import tools.HtmlTools;
import tools.NativeString;
import ui.ChromeTabs;
import ui.Preferences;
using tools.PathTools;
import gml.file.GmlFile;
import ui.GlobalSearch;
import ui.project.ProjectProperties;
import ui.project.ProjectData;
import ui.treeview.TreeView;
import ui.treeview.TreeViewElement;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class Project {
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
	/** current configuration name */
	public var config:String = "default";
	
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
	/** Resource name -> "GMScript"/etc. (2.3 only) */
	public var yyResourceTypes:Dictionary<String>;
	/** GUID -> URL */
	public var yySpriteURLs:Dictionary<String>;
	/** Resource name -> 2.3 order */
	public var yyOrder:Dictionary<Int>;
	
	/** Whether this is a new-format GMS2.3 project */
	public var isGMS23:Bool = false;
	/** Whether to use extended JSON syntax (int64 support, trailing commas) */
	public var yyExtJson:Bool = false;
	/** This will be false for 2.3 */
	public var yyUsesGUID:Bool = true;
	
	/** name -> URL */
	public var spriteURLs:Dictionary<String> = new Dictionary();
	
	/** object name -> object parent name */
	public var objectParents:Dictionary<String>;
	/** object name -> [...child names] */
	public var objectChildren:Dictionary<Array<String>>;
	//
	public var hasGMLive:Bool = false;
	
	public var properties:ProjectData = cast {};
	public var propertiesElement:DivElement = null;
	
	/** whether X is a lambda script */
	public var lambdaMap:Dictionary<Bool> = new Dictionary();
	public var lambdaExt:RelPath = null;
	/** path to .gml file with lambdas */
	public var lambdaGml:RelPath = null;
	/** lambdas view if in scripts mode */
	public var lambdaView:RelPath = null;
	public inline function canLambda():Bool {
		return !isGMS23
			&& Preferences.current.lambdaMagic
			&& (lambdaGml != null || properties.lambdaMode == Scripts);
	}
	
	private var frameRate:Null<Int> = null;
	public function getFrameRate():Int {
		// Going to let this be synchronous as otherwise we might
		// fetch it several times in parallel while restoring tabs.
		var r = frameRate;
		if (r == null) switch (version.config.projectModeId) {
			case 1 if (gmxFirstRoomName != null): {
				try {
					var txt = readTextFileSync("rooms/" + gmxFirstRoomName + ".room.gmx");
					var rx = new RegExp("<speed>(\\d+)</speed>");
					var mt = rx.exec(txt);
					r = mt != null ? Std.parseInt(mt[1]) : 30;
				} catch (_:Dynamic) {
					r = 30;
				}
			};
			case 2: {
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
					version = GmlVersion.v1;
					findV1(outer2);
				}
				if (version == GmlVersion.none) {
					version = GmlVersion.detect(FileSystem.readTextFileSync(_path));
					if (version == GmlVersion.none) version = GmlVersion.v2;
				}
				delayTab();
			};
		}
	}
	#end
	public function new(_path:String, _load:Bool = true) {
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
		if (_load) {
			document.title = path != "" ? (displayName + " - GMEdit") : "GMEdit";
			TreeView.clear();
			reload(true);
		}
		#else
		version = GmlAPI.version;
		#end
	}
	public function detectVersion() {
		if (path == "") {
			name = "";
			version = GmlVersion.none;
			displayName = "Recent projects";
		} else {
			var pair = path.ptDetectProject();
			version = pair.version;
			displayName = pair.name;
		}
	}
	public static function open(path:String) {
		if (current != null) current.close();
		current = new Project(path);
		if (path != "") ui.RecentProjects.add(current.path != null ? current.path : path);
	}
	public function close() {
		if (version != GmlVersion.none) {
			PluginEvents.projectClose({project:current});
		}
		TreeView.saveOpen();
		var tabPaths:Array<String> = [];
		var activeTab:Null<Int> = null;
		for (_tab in ChromeTabs.element.querySelectorAll(".chrome-tab")) try {
			var tab:ChromeTab = cast _tab;
			var path = tab.gmlFile.path;
			if (path != null) {
				if (tab.classList.contains("chrome-tab-current")) activeTab = tabPaths.length;
				tabPaths.push(path);
			}
		} catch (_:Dynamic) { }
		var data:ProjectState = {
			treeviewScrollTop: TreeView.element.scrollTop,
			treeviewOpenNodes: TreeView.openPaths,
			tabPaths: tabPaths,
			activeTab: activeTab,
		};
		PluginEvents.projectStateSave({project:this, state:data});
		window.localStorage.setItem("project:" + path, Json.stringify(data));
		window.localStorage.setItem("@project:" + path, "" + Date.now().getTime());
	}
	public var firstLoadState:ProjectState = null;
	public function finishedIndexing() {
		nameNode.innerText = displayName;
		if (current.hasGMLive) ui.GMLive.updateAll();
		//
		if (isGMS23) {
			@:privateAccess YyLoader.folderMap = null;
			for (pair in @:privateAccess YyLoader.itemsToInsert) {
				var el:TreeViewElement = pair.item;
				TreeView.insertSorted(pair.dir, el);
				var th = TreeView.thumbMap[el.treeFullPath];
				if (th != null) TreeView.setThumb(null, th, el);
			}
		}
		// try restoring tabs:
		var state = firstLoadState;
		if (state != null) {
			firstLoadState = null;
			var tabPaths = state.tabPaths;
			if (tabPaths != null) {
				var activeFile = null;
				for (i in 0 ... tabPaths.length) try {
					var el = TreeView.find(true, { path: tabPaths[i] });
					if (el != null) {
						var file = TreeView.handleItemClick(null, el, {noExtern:true});
						if (i == state.activeTab) activeFile = file;
					}
				} catch (x:Dynamic) {
					Main.console.error("Error recovering " + path + ":", x);
				}
				if (activeFile != null) activeFile.tabEl.click();
			}
			PluginEvents.projectStateRestore({project:this, state:state});
		}
	}
	//
	public static function init() {
		loaderMap = {
			"gms1": GmxLoader.run,
			"gms2": YyLoader.run,
			"gmk-splitter": GmkLoader.run,
			"directory": RawLoader.run,
		};
		searchMap = {
			"gms1": GmxSearcher.run,
			"gms2": YySearcher.run,
			"gmk-splitter": GmkSearcher.run,
			"directory": RawSearcher.run,
		};
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
			var tmp = new Project("", false);
			current = tmp;
			window.setTimeout(function() {
				ui.FileDrag.handle(path.ptNoBS(), null);
				if (current == tmp) {
					open("");
					document.title = path.ptNoDir() + " - GMEdit";
				}
			});
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
			objectParents = new Dictionary();
			if (version.name == "v2" && first) {
				var yypContent = readTextFileSync(name);
				if (YyLoader.isV23(yypContent)) {
					version = GmlVersion.map["v23"];
				}
				@:privateAccess YyLoader.nextYypContent = yypContent;
			}
			GmlAPI.version = version;
			var state:ProjectState = null;
			if (first) {
				properties = ProjectProperties.load(this);
				GmlAPI.forceTemplateStrings = properties.templateStringScript != null;
				GmlSeekData.map = new Dictionary();
				try {
					var stateText = window.localStorage.getItem("project:" + path);
					state = Json.parse(stateText);
				} catch (_:Dynamic) { }
			} else {
				TreeView.saveOpen();
				if (Preferences.current.clearAssetThumbsOnRefresh) {
					spriteURLs = new Dictionary();
					yySpriteURLs = new Dictionary();
				}
			}
			reload_1();
			ace.AceTooltips.resetCache();
			TreeView.restoreOpen(state != null ? state.treeviewOpenNodes : null);
			if (state != null) {
				TreeView.element.scrollTop = state.treeviewScrollTop;
				if (first) firstLoadState = state;
			}
			if (GmlSeeker.itemsLeft == 0) {
				nameNode.innerText = displayName;
			} else nameNode.innerText = "Indexing...";
			
			if (Electron != null && ui.Preferences.current.taskbarOverlays) try {
				if (version != GmlVersion.none) {
					if (!isVirtual && existsSync(name + ".taskbar-overlay.png")) {
						electron.IPC.send("set-taskbar-icon", path + ".taskbar-overlay.png", "");
					} else {
						var vov = version.dir + "/taskbar-overlay.png";
						if (FileSystem.existsSync(vov)) {
							electron.IPC.send("set-taskbar-icon", vov, version.label);
						} else electron.IPC.send("set-taskbar-icon", null, "");
					}
				} else electron.IPC.send("set-taskbar-icon", null, "");
			} catch (x:Dynamic) {}
			
			if (PluginManager.ready == true && version != GmlVersion.none) {
				PluginEvents.projectOpen({project:this});
			}
			ui.ProjectStyle.reload();
		}, 1);
	}
	public static var loaderMap:DynamicAccess<Project->Void> = null; // -> init
	private function reload_1() {
		if (version == GmlVersion.none) {
			ui.RecentProjects.show();
		} else if (path == null) {
			TreeView.clear();
		} else {
			var func = loaderMap[version.config.loadingMode];
			if (func != null) func(this);
		}
	}
	//
	/** fn(name, path, code), */
	public static var searchMap:DynamicAccess<(pj:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt)->Void> = null; // -> init
	public function search(fn:ProjectSearcher, done:Void->Void, ?opt:GlobalSearchOpt) {
		var func = searchMap[version.config.searchMode];
		if (func != null) {
			func(this, fn, done, opt);
		} else done();
	}
	//
	public function fullPath(path:String):FullPath {
		if (dir != "") {
			return (dir + "/" + path).ptNoBS();
		} else return path;
	}
	public function relPath(path:FullPath):RelPath {
		if (dir != "" && NativeString.startsWith(path, dir)) {
			var p = dir.length;
			switch (path.charCodeAt(p)) {
				case "/".code, "\\".code: return path.substring(p + 1);
			}
		}
		return path;
	}
	public function existsSync(path:String):Bool {
		return FileSystem.existsSync(fullPath(path));
	}
	/** Returns modified time of a file, null if not existing */
	public function mtimeSync(path:String):Null<Float> {
		return FileSystem.mtimeSync(fullPath(path));
	}
	//
	public function unlinkSync(path:String):Void {
		FileSystem.unlinkSync(fullPath(path));
	}
	public function unlinkSyncSafe(path:String):Void {
		if (existsSync(path)) unlinkSync(path);
	}
	//
	public function readTextFile(path:String, fn:Error->String->Void):Void {
		FileSystem.readTextFile(fullPath(path), fn);
	}
	public function readTextFileSync(path:String):String {
		return FileSystem.readTextFileSync(fullPath(path));
	}
	public function writeTextFileSync(path:String, text:String) {
		FileSystem.writeFileSync(fullPath(path), text);
	}
	//
	public function readJsonFile<T:{}>(path:String, callback:Error->T->Void):Void {
		readTextFile(path, function(e:Error, d:Dynamic) {
			if (e == null) try {
				d = Json.parse(d);
			} catch (x:Dynamic) {
				d = null;
				e = x;
			}
			callback(e, d);
		});
	}
	public function readYyFile<T:{}>(path:String, callback:Error->T->Void):Void {
		readTextFile(path, function(e:Error, d:Dynamic) {
			if (e == null) try {
				d = YyJson.parse(d);
			} catch (x:Dynamic) {
				d = null;
				e = x;
			}
			callback(e, d);
		});
	}
	//
	public function readJsonFileSync<T>(path:String):T {
		return Json.parse(readTextFileSync(path));
	}
	public function readYyFileSync(path:String):Dynamic {
		return YyJson.parse(readTextFileSync(path));
	}
	public inline function writeJsonFileSync(path:String, value:Dynamic) {
		writeTextFileSync(path, NativeString.yyJson(value));
	}
	public inline function writeYyFileSync(path:String, value:Dynamic) {
		writeTextFileSync(path, YyJsonPrinter.stringify(value, yyExtJson));
	}
	//
	public function readGmxFile(path:String, fn:Error->SfGmx->Void):Void {
		return FileSystem.readGmxFile(fullPath(path), fn);
	}
	public function readGmxFileSync(path:String):SfGmx {
		return FileSystem.readGmxFileSync(fullPath(path));
	}
	public function writeGmxFileSync(path:String, gmx:SfGmx) {
		writeTextFileSync(path, gmx.toGmxString());
	}
	public function writeGmkSplitFileSync(path:String, xml:SfGmx) {
		writeTextFileSync(path, xml.toGmkSplitString());
	}
	//
	/**
	 * Reads a JSON file relative to #config directory.
	 * Returns null if something goes wrong.
	 */
	public function readConfigJsonFileSync<T:{}>(path:String):T {
		if (existsSync("#config")) {
			var full = "#config/" + path;
			if (existsSync(full)) {
				try {
					return readJsonFileSync(full);
				} catch (x:Dynamic) {
					Main.console.error('Failed to read `$full`:', x);
				}
			}
		}
		return null;
	}
	public function writeConfigJsonFileSync(path:String, value:Dynamic):Void {
		if (!existsSync("#config")) mkdirSync("#config");
		writeJsonFileSync("#config/" + path, value);
	}
	//
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
		var t = mtimeSync(path);
		return t != null ? 'file:///$full?mtime=$t' : null;
	}
	/**
	 * Like getImageURL but takes a sprite name and gets you a URL for it's first frame
	 * Generally used for thumbnails.
	 */
	public function getSpriteURL(name:String):String {
		var vi = version.config.projectModeId;
		if (vi == Other) return null;
		if (spriteURLs.exists(name)) {
			return spriteURLs[name];
		}
		var r:String;
		switch (vi) {
			case GmkSplitter: r = getImageURL("sprites/" + name + ".images/image 0.png");
			case GMS1: r = getImageURL("sprites/images/" + name + "_0.png");
			case GMS2: {
				var g:YyGUID = yyResourceGUIDs[name];
				if (g != null) {
					if (yySpriteURLs.exists(g)) {
						r = yySpriteURLs[g];
					} else try {
						var spritePath = yyUsesGUID
							? yyResources[g].Value.resourcePath
							: yyResources[g].id.path;
						var sprite:YySprite = readYyFileSync(spritePath);
						var frame = sprite.frames[0];
						if (frame != null) {
							var frameName:String = yyUsesGUID ? frame.id : frame.name;
							var framePath = Path.join([Path.directory(spritePath), frameName + ".png"]);
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
		if (version.config.projectMode == null) return;
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
		switch (version.config.projectModeId) {
			case GmkSplitter: {
				var full = fullPath("sprites/" + name + ".images/image 0.png");
				FileSystem.access(full, FileSystemAccess.Exists, function(e) {
					full = e == null ? "file:///" + full : null;
					now(full);
				});
			}
			case GMS1: {
				var full = fullPath("sprites/images/" + name + "_0.png");
				FileSystem.access(full, FileSystemAccess.Exists, function(e) {
					full = e == null ? "file:///" + full : null;
					now(full);
				});
			}
			case GMS2: {
				var g:YyGUID = yyResourceGUIDs[name];
				if (g != null) {
					if (yySpriteURLs.exists(g)) {
						soon(yySpriteURLs[g]);
					} else {
						var yyRes = yyResources[g];
						var spritePath = (yyRes.Value != null
							? yyRes.Value.resourcePath
							: yyRes.id.path
						);
						readYyFile(spritePath, function(e, sprite:YySprite) {
							var r:String;
							if (e == null) {
								var frame = sprite.frames[0];
								if (frame != null) {
									var fid = frame.name;
									if (fid == null) fid = frame.id;
									var framePath = Path.join([Path.directory(spritePath), fid + ".png"]);
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
	/** Recursive directory removal. Not too smart, won't retry */
	public function rmdirRecSync(path:String):Bool {
		var ok = true;
		for (pair in readdirSync(path)) {
			if (pair.isDirectory) {
				if (!rmdirRecSync(pair.relPath)) ok = false;
			} else try {
				unlinkSync(pair.relPath);
			} catch (x:Dynamic) {
				Main.console.warn(x);
				ok = false;
			}
		}
		if (ok) try {
			rmdirSync(dir);
		} catch (x:Dynamic) {
			Main.console.warn(x);
		}
		return ok;
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
						relPath: path + "/" + rel,
						fullPath: itemFull,
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
				relPath: Path.join([path, rel]),
				fullPath: itemFull,
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
	?activeTab:Int,
}
typedef ProjectDirInfo = {
	fileName:String,
	relPath:String,
	fullPath:String,
	isDirectory:Bool,
}
