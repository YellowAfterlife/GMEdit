package gml;
import ace.AceWrap.AceAutoCompleteItem;
import electron.FileSystem;
import electron.Electron;
import haxe.io.Path;
import js.Boot;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import tools.Dictionary;
import gml.GmlAPI;
import ace.AceWrap;
import gmx.SfGmx;
import Main.*;
import tools.HtmlTools;
import gml.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class Project {
	//
	public static var current:Project = null;
	public static var assetTypes:Array<String> = [
		"sprite", "background", "sound", "path", "font",
		"shader", "timeline", "script", "object", "room"
	];
	//
	public static var nameNode = document.querySelector("#project-name");
	public static var toggleCode = ('var cl = this.parentElement.classList;'
		+ ' if (cl.contains("open")) cl.remove("open"); else cl.add("open");'
		+ ' return false;');
	public static function openFile(name:String, path:String) {
		// see if there's an existing tab for this:
		for (tabNode in document.querySelectorAll('.chrome-tab')) {
			var tabEl:Element = cast tabNode;
			var gmlFile:gml.GmlFile = untyped tabEl.gmlFile;
			if (gmlFile != null && gmlFile.path == path) {
				tabEl.click();
				return;
			}
		}
		// determine what to do with the file:
		var kind:GmlFileKind;
		var ext = Path.extension(path).toLowerCase();
		switch (ext) {
			case "gml": kind = Normal;
			case "gmx": {
				ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
				kind = switch (ext) {
					case "object": GmxObjectEvents;
					case "project": GmxProjectMacros;
					case "config": GmxConfigMacros;
					default: Extern;
				}
			};
			default: kind = Extern;
		}
		//
		if (kind != Extern) {
			// addTab doesn't return the new tab so we bind it up in the "active tab change" event:
			gml.GmlFile.next = new gml.GmlFile(name, path, kind);
			chromeTabs.addTab({ title: name, });
		} else {
			Electron.shell.openItem(path);
		}
	}
	public static function openEvent(e:MouseEvent) {
		var el:Element = cast e.target;
		if (!el.classList.contains("item")) el = el.parentElement;
		openFile(el.innerText, el.getAttribute("path"));
		e.preventDefault();
	}
	//
	public var name:String;
	public var path:String;
	public var dir:String;
	public var gmx:SfGmx;
	public function new(path:String) {
		this.path = path;
		dir = Path.directory(path);
		name = Path.withoutDirectory(path);
		document.title = name;
		reload();
	}
	public function reload() {
		nameNode.innerText = "Loading...";
		window.setTimeout(function() {
			reload_1();
			nameNode.innerText = "";
		}, 1);
	}
	public function reload_1() {
		gmx = FileSystem.readGmxFileSync(path);
		//
		GmlAPI.gmlClear();
		var rxName = ~/^.+[\/\\](\w+)(?:\.[\w.]+)?$/g;
		var tv = treeview;
		var tvOpen = [];
		for (tvNode in tv.querySelectorAll(".dir.open")) {
			var tvDir:Element = cast tvNode;
			tvOpen.push(tvDir.getAttribute("path"));
		}
		tv.innerHTML = "";
		function makeDir(name:String, path:String):TreeViewDir {
			var r:TreeViewDir = cast document.createDivElement();
			r.className = "dir";
			//
			var header = document.createDivElement();
			header.className = "header";
			header.setAttribute("onclick", toggleCode);
			header.title = name;
			r.appendChild(header);
			//
			var span = document.createSpanElement();
			span.appendChild(document.createTextNode(name));
			header.appendChild(span);
			//
			r.setAttribute("path", path);
			var c = document.createDivElement();
			c.className = "items";
			r.treeItems = c;
			r.appendChild(c);
			return r;
		}
		function makeItem(name:String, path:String) {
			var r = document.createDivElement();
			r.className = "item";
			var span = document.createSpanElement();
			span.appendChild(document.createTextNode(name));
			r.appendChild(span);
			r.title = name;
			r.setAttribute("path", path);
			r.addEventListener("dblclick", openEvent);
			return r;
		}
		function loadrec(gmx:SfGmx, out:Element, one:String, path:String) {
			if (gmx.name == one) {
				var path = gmx.text;
				var name = rxName.replace(path, "$1");
				path = Path.join([dir, path]);
				var _main:String;
				if (one != "script") {
					path += '.$one.gmx';
					_main = "";
				} else {
					_main = name;
					gml.GmlSeeker.run(path, _main);
				}
				var r = makeItem(name, path);
				out.appendChild(r);
			} else {
				var name = gmx.get("name");
				if (out == tv) name = name.charAt(0).toUpperCase() + name.substring(1);
				var next = path + name + "/";
				var r = makeDir(name, next);
				var c = r.treeItems;
				for (q in gmx.children) loadrec(q, c, one, next);
				out.appendChild(r);
			}
		}
		for (q in gmx.findAll("scripts")) loadrec(q, tv, "script", "scripts/");
		for (q in gmx.findAll("objects")) loadrec(q, tv, "object", "objects/");
		//
		GmlAPI.extClear();
		var comp = GmlAPI.gmlComp;
		for (extParent in gmx.findAll("NewExtensions")) {
			var extNodes = extParent.findAll("extension");
			if (extNodes.length == 0) continue;
			var extParentDir = makeDir("Extensions", "extensions/");
			for (extNode in extNodes) {
				var extRel = extNode.text;
				var extPath = Path.join([dir, extRel + ".extension.gmx"]);
				var extGmx = FileSystem.readGmxFileSync(extPath);
				var extName = extGmx.findText("name");
				var extDir = makeDir(extName, "extensions/" + extName + "/");
				for (extFiles in extGmx.findAll("files"))
				for (extFile in extFiles.findAll("file")) {
					var extFileName = extFile.findText("filename");
					var extFilePath = Path.join([dir, extNode.text, extFileName]);
					extDir.treeItems.appendChild(makeItem(extFileName, extFilePath));
					//
					for (funcs in extFile.findAll("functions"))
					for (func in funcs.findAll("function")) {
						var name = func.findText("name");
						GmlAPI.extKind.set(name, "extfunction");
						var help = func.findText("help");
						if (help != null && help != "") {
							GmlAPI.extComp.push(new AceAutoCompleteItem(name, "function", help));
							GmlAPI.extDoc.set(name, GmlAPI.parseDoc(help));
						}
					}
					//
					for (mcrs in extFile.findAll("constants"))
					for (mcr in mcrs.findAll("constant"))
					if (mcr.findText("hidden") == "0") {
						var name = mcr.findText("name");
						var expr = mcr.findText("value");
						GmlAPI.extComp.push(new AceAutoCompleteItem(name, "macro", expr));
						GmlAPI.extKind.set(name, "extmacro");
					}
				} // for (extFile)
				extParentDir.treeItems.appendChild(extDir);
			}
			tv.appendChild(extParentDir);
		}
		//
		var mcrDir = makeDir("Macros", "macros/");
		var mcrItems = mcrDir.querySelector(".items");
		mcrItems.appendChild(makeItem("All configurations", path));
		for (configs in gmx.findAll("Configs")) {
			for (config in configs.findAll("Config")) {
				var configPath = config.text;
				var configName = rxName.replace(configPath, "$1");
				configPath = Path.join([dir, configPath + ".config.gmx"]);
				mcrItems.appendChild(makeItem(configName, configPath));
			}
		}
		tv.appendChild(mcrDir);
		//{
		function loadAssets(r:Dictionary<String>, single:String, ?plural:String) {
			if (plural == null) plural = single + "s";
			var id:Int = 0;
			var ids = GmlAPI.gmlAssetIDs[single];
			for (section in gmx.findAll(plural)) for (item in section.findRec(single)) {
				var name = rxName.replace(item.text, "$1");
				r.set(name, "asset." + single);
				comp.push(new AceAutoCompleteItem(name, single));
				ids.set(name, id++);
			}
		}
		//
		var tm = new Dictionary();
		for (type in assetTypes) loadAssets(tm, type);
		//
		function addMacros(ctr:SfGmx) {
			for (q in ctr.findAll("constant")) {
				var name = q.get("name");
				var expr = q.text;
				tm.set(name, "macro");
				comp.push(new AceAutoCompleteItem(name, "macro", expr));
			}
		}
		for (ctr in gmx.findAll("constants")) addMacros(ctr);
		//
		for (configs in gmx.findAll("Configs")) {
			var confNode = configs.find("Config");
			if (confNode != null) {
				var cpath = Path.join([dir, confNode.text + ".config.gmx"]);
				var cgmx = FileSystem.readGmxFileSync(cpath);
				for (outer in cgmx.findAll("ConfigConstants")) {
					for (ctr in outer.findAll("constants")) addMacros(ctr);
				}
			}
		}
		//
		for (tvPath in tvOpen) {
			var tvDir = tv.querySelector('.dir[path="$tvPath"]');
			if (tvDir != null) tvDir.classList.add("open");
		}
		//
		GmlAPI.gmlKind = tm;
		//}
	}
}
