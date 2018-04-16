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
import ui.TreeView;

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
	//
	public var hasGMLive:Bool = false;
	//
	public function new(path:String) {
		this.path = path;
		dir = Path.directory(path);
		name = Path.withoutDirectory(path);
		detectVersion();
		document.title = name != "" ? (name + " - GMEdit") : "GMEdit";
		TreeView.clear();
		reload(true);
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
		if (path != "") ui.RecentProjects.add(path);
		current = new Project(path);
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
				var t = Std.parseFloat(ls.getItem(k));
				if (Std.parseFloat(ls.getItem(k)) < remTime) {
					remList.push(k);
					remList.push(k.substring(1));
				}
			}
		}
		for (remKey in remList) ls.removeItem(remKey);
		//
		var path = moduleArgs["open"];
		if (path == null || path == "") path = window.localStorage.getItem("autoload");
		open(path != null ? path : "");
	}
	//
	public function reload(?first:Bool) {
		nameNode.innerText = "Loading...";
		window.setTimeout(function() {
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
		switch (version) {
			case GmlVersion.v1: GmxLoader.run(this);
			case GmlVersion.v2: YyLoader.run(this);
			case GmlVersion.live: GmlLoader.run(this);
			case GmlVersion.none: ui.RecentProjects.show();
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
	public inline function relPath(path:String) {
		return Path.join([dir, path]);
	}
	public function existsSync(path:String):Bool {
		return FileSystem.existsSync(relPath(path));
	}
	public function unlinkSync(path:String):Void {
		FileSystem.unlinkSync(relPath(path));
	}
	public function readTextFile(path:String, fn:Error->String->Void):Void {
		FileSystem.readTextFile(relPath(path), fn);
	}
	public function readTextFileSync(path:String):String {
		return FileSystem.readTextFileSync(relPath(path));
	}
	public function readJsonFile<T:{}>(path:String, fn:Error->T->Void):Void {
		FileSystem.readJsonFile(relPath(path), fn);
	}
	public function readJsonFileSync<T>(path:String):T {
		return FileSystem.readJsonFileSync(relPath(path));
	}
	public function readGmxFileSync(path:String):SfGmx {
		return FileSystem.readGmxFileSync(relPath(path));
	}
	public function writeTextFileSync(path:String, text:String) {
		FileSystem.writeFileSync(path, text);
	}
	public function getImageURL(path:String):String {
		var full = relPath(path);
		return FileSystem.existsSync(full) ? ("file:///" + full) : null;
	}
	public function readdirSync(path:String):Array<ProjectDirInfo> {
		var full = relPath(path);
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
