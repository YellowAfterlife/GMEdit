package gml;
import ace.AceWrap.AceAutoCompleteItem;
import electron.FileSystem;
import electron.Electron;
import haxe.Json;
import haxe.io.Path;
import js.Boot;
import js.Error;
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
	//
	public var yyObjectNames:Dictionary<String>;
	public var yyObjectGUIDs:Dictionary<YyGUID>;
	public var yyResources:Dictionary<YyProjectResource>;
	/** object name -> [...child names] */
	public var objectChildren:Dictionary<Array<String>>;
	//
	public var hasGMLive:Bool = false;
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
		var data:ProjectState = {
			treeviewScrollTop: TreeView.element.scrollTop,
			treeviewOpenNodes: TreeView.openPaths,
		};
		window.localStorage.setItem("project:" + path, Json.stringify(data));
		window.localStorage.setItem("@project:" + path, "" + Date.now().getTime());
	}
	//
	public static function init() {
		//
		var ls = window.localStorage;
		var remList:Array<String> = [];
		var remTime:Float = Date.now().getTime()
			- (1000 * 60 * 60 * 24 * ui.Preferences.current.projectSessionTime);
		for (i in 0 ... ls.length) {
			var k = ls.key(i);
			if (NativeString.startsWith(k, "@project:")) {
				if (Std.parseFloat(ls.getItem(k)) < remTime) {
					remList.push(k);
					remList.push(k.substring(1));
				}
			}
		}
		for (remKey in remList) ls.removeItem(remKey);
		//
		#if !lwedit
		var path = moduleArgs["open"];
		//if (path == null || path == "") path = window.localStorage.getItem("autoload");
		open(path != null ? path : "");
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
			TreeView.restoreOpen(state != null ? state.treeviewOpenNodes : null);
			if (state != null) TreeView.element.scrollTop = state.treeviewScrollTop;
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
			return dir + "/" + path;
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
	public function getImageURL(path:String):String {
		var full = fullPath(path);
		return FileSystem.existsSync(full) ? ("file:///" + full) : null;
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
}
typedef ProjectDirInfo = {
	fileName:String,
	isDirectory:Bool,
}
