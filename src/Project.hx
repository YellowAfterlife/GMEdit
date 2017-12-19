package;
import ace.AceWrap.AceAutoCompleteItem;
import haxe.io.Path;
import js.Boot;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import tools.Dictionary;
import ace.GmlAPI;
import ace.AceWrap;
import gmx.SfGmx;
import Main.*;
import tools.HtmlTools;
import GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class Project {
	public static var nameNode = document.querySelector("#project-name");
	public static var toggleCode = ('var cl = this.parentElement.classList;'
		+ ' if (cl.contains("open")) cl.remove("open"); else cl.add("open");'
		+ ' return false;');
	public static function openFile(name:String, path:String) {
		// see if there's an existing tab for this:
		for (tabNode in document.querySelectorAll('.chrome-tab')) {
			var tabEl:Element = cast tabNode;
			var gmlFile:GmlFile = untyped tabEl.gmlFile;
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
					case "object": GmxObject;
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
			GmlFile.next = new GmlFile(name, path, kind);
			chromeTabs.addTab({ title: name, });
		} else {
			electron.shell.openItem(path);
		}
	}
	public static function openEvent(e:MouseEvent) {
		var el:Element = cast e.target;
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
		gmx = SfGmx.parse(nodefs.readFileSync(path, "utf8"));
		//
		var comp = GmlAPI.gmlComp;
		comp.clear();
		//
		var rxName = ~/^.+[\/\\](\w+)(?:\.[\w.]+)?$/g;
		var tv = treeview;
		tv.innerHTML = "";
		function makeDir(name:String):TreeViewDir {
			var r:TreeViewDir = cast document.createDivElement();
			r.className = "dir";
			var h = document.createDivElement();
			h.className = "header";
			h.appendChild(document.createTextNode(name));
			h.setAttribute("onclick", toggleCode);
			r.appendChild(h);
			var c = document.createDivElement();
			c.className = "items";
			r.treeItems = c;
			r.appendChild(c);
			return r;
		}
		function makeItem(name:String, path:String) {
			var r = document.createDivElement();
			r.className = "item";
			r.appendChild(document.createTextNode(name));
			r.title = name;
			r.setAttribute("path", path);
			r.addEventListener("dblclick", openEvent);
			return r;
		}
		function loadrec(gmx:SfGmx, out:Element, one:String) {
			if (gmx.name == one) {
				var path = gmx.text;
				var name = rxName.replace(path, "$1");
				if (one != "script") path += '.$one.gmx';
				path = Path.join([dir, path]);
				var r = makeItem(name, path);
				out.appendChild(r);
			} else {
				var name = gmx.get("name");
				if (out == tv) name = name.charAt(0).toUpperCase() + name.substring(1);
				var r = makeDir(name);
				var c = r.treeItems;
				for (q in gmx.children) loadrec(q, c, one);
				out.appendChild(r);
			}
		}
		for (q in gmx.findAll("scripts")) loadrec(q, tv, "script");
		for (q in gmx.findAll("objects")) loadrec(q, tv, "object");
		//
		GmlAPI.extComp.clear();
		GmlAPI.extDoc = new Dictionary();
		GmlAPI.extKind = new Dictionary();
		for (extParent in gmx.findAll("NewExtensions")) {
			var extNodes = extParent.findAll("extension");
			if (extNodes.length == 0) continue;
			var extParentDir = makeDir("Extensions");
			for (extNode in extNodes) {
				var extName = extNode.text;
				var extPath = Path.join([dir, extName + ".extension.gmx"]);
				var extGmx = SfGmx.parse(nodefs.readFileSync(extPath, "utf8"));
				var extDir = makeDir(extName);
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
		var mcrDir = makeDir("Macros");
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
			for (section in gmx.findAll(plural)) for (item in section.findRec(single)) {
				var name = rxName.replace(item.text, "$1");
				r.set(name, "asset." + single);
				comp.push(new AceAutoCompleteItem(name, single));
			}
		}
		//
		var tm = new Dictionary();
		loadAssets(tm, "sprite");
		loadAssets(tm, "background");
		loadAssets(tm, "sound");
		loadAssets(tm, "path");
		loadAssets(tm, "font");
		loadAssets(tm, "shader");
		loadAssets(tm, "timeline");
		loadAssets(tm, "script");
		loadAssets(tm, "object");
		loadAssets(tm, "room");
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
				var cgmx = SfGmx.parse(nodefs.readFileSync(cpath, "utf8"));
				for (outer in cgmx.findAll("ConfigConstants")) {
					for (ctr in outer.findAll("constants")) addMacros(ctr);
				}
			}
		}
		//
		GmlAPI.gmlKind = tm;
		//}
	}
}
