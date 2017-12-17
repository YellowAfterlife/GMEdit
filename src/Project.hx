package;
import ace.AceWrap.AceAutoCompleteItem;
import haxe.io.Path;
import js.Boot;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import tools.Dictionary;
import ace.GmlAPI;
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
		for (tabNode in document.querySelectorAll('.chrome-tab')) {
			var tabEl:Element = cast tabNode;
			var gmlFile:GmlFile = untyped tabEl.gmlFile;
			if (gmlFile != null && gmlFile.name == name) {
				tabEl.click();
				return;
			}
		}
		// addTab doesn't return the new tab so we bind it up in "active tab change" event:
		var ext = Path.extension(path).toLowerCase();
		if (ext == "gmx") {
			ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
		}
		var kind:GmlFileKind = switch (ext) {
			case "object": GmxObject;
			case "project": GmxProjectMacros;
			case "config": GmxConfigMacros;
			default: Normal;
		}
		GmlFile.next = new GmlFile(name, path, kind);
		chromeTabs.addTab({ title: name, });
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
		function makeDir(name:String) {
			var r = document.createDivElement();
			r.className = "dir";
			var h = document.createDivElement();
			h.className = "header";
			h.appendChild(document.createTextNode(name));
			h.setAttribute("onclick", toggleCode);
			r.appendChild(h);
			var c = document.createDivElement();
			c.className = "items";
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
			var r:DivElement, name:String;
			if (gmx.name == one) {
				var path = gmx.text;
				name = rxName.replace(path, "$1");
				if (one != "script") path += '.$one.gmx';
				path = Path.join([dir, path]);
				r = makeItem(name, path);
			} else {
				name = gmx.get("name");
				if (out == tv) name = name.charAt(0).toUpperCase() + name.substring(1);
				r = makeDir(name);
				var c = r.querySelector(".items");
				for (q in gmx.children) loadrec(q, c, one);
			}
			out.appendChild(r);
		}
		for (q in gmx.findAll("scripts")) loadrec(q, tv, "script");
		for (q in gmx.findAll("objects")) loadrec(q, tv, "object");
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
		for (cat in gmx.findAll("constants"))
		for (q in cat.findAll("constant")) {
			var name = q.get("name");
			var expr = q.text;
			tm.set(name, "macro");
			comp.push(new AceAutoCompleteItem(name, "macro", expr));
		}
		GmlAPI.gmlKind = tm;
		//}
	}
}
