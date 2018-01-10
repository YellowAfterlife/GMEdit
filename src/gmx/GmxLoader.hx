package gmx;
import gml.*;
import ui.*;
import electron.FileSystem;
import js.html.Element;
import haxe.io.Path;
import ace.AceWrap;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxLoader {
	public static var assetTypes:Array<String> = [
		"sprite", "background", "sound", "path", "font",
		"shader", "timeline", "script", "object", "room"
	];
	public static function run(project:Project) {
		var path = project.path;
		var dir = project.dir;
		var gmx = FileSystem.readGmxFileSync(path);
		//
		GmlAPI.gmlClear();
		var rxName = ~/^.+[\/\\](\w+)(?:\.[\w.]+)?$/g;
		TreeView.clear();
		var tv = TreeView.element;
		function loadrec(gmx:SfGmx, out:Element, one:String, path:String) {
			if (gmx.name == one) {
				var path = gmx.text;
				var name = rxName.replace(path, "$1");
				var full = Path.join([dir, path]);
				var _main:String = "";
				switch (one) {
					case "script": _main = name;
					case "shader": { };
					default: full += '.$one.gmx';
				}
				GmlAPI.gmlLookupText += name + "\n";
				gml.GmlSeeker.run(full, _main);
				out.appendChild(TreeView.makeItem(name, path, full, one));
			} else {
				var name = gmx.get("name");
				if (out == tv) name = name.charAt(0).toUpperCase() + name.substring(1);
				var next = path + name + "/";
				var r = TreeView.makeDir(name, next);
				var c = r.treeItems;
				for (q in gmx.children) loadrec(q, c, one, next);
				out.appendChild(r);
			}
		}
		for (q in gmx.findAll("scripts")) loadrec(q, tv, "script", "scripts/");
		for (q in gmx.findAll("shaders")) loadrec(q, tv, "shader", "shaders/");
		for (q in gmx.findAll("timelines")) loadrec(q, tv, "timeline", "timelines/");
		for (q in gmx.findAll("objects")) loadrec(q, tv, "object", "objects/");
		//
		GmlAPI.extClear();
		var comp = GmlAPI.gmlComp;
		for (extParent in gmx.findAll("NewExtensions")) {
			var extNodes = extParent.findAll("extension");
			if (extNodes.length == 0) continue;
			var extParentDir = TreeView.makeDir("Extensions", "extensions/");
			for (extNode in extNodes) {
				var extRel = extNode.text;
				var extPath = Path.join([dir, extRel + ".extension.gmx"]);
				var extGmx = FileSystem.readGmxFileSync(extPath);
				var extName = extGmx.findText("name");
				var extDir = TreeView.makeDir(extName, "extensions/" + extName + "/");
				for (extFiles in extGmx.findAll("files"))
				for (extFile in extFiles.findAll("file")) {
					var extFileName = extFile.findText("filename");
					var extFilePath = Path.join([extNode.text, extFileName]);
					var extFileFull = Path.join([dir, extFilePath]);
					extDir.treeItems.appendChild(TreeView.makeItem(
						extFileName, extFilePath, extFileFull, "extfile"
					));
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
					for (mcr in mcrs.findAll("constant")) {
						var name = mcr.findText("name");
						GmlAPI.extKind.set(name, "extmacro");
						if (mcr.findText("hidden") == "0") {
							var expr = mcr.findText("value");
							GmlAPI.extComp.push(new AceAutoCompleteItem(name, "macro", expr));
						}
					}
				} // for (extFile)
				extParentDir.treeItems.appendChild(extDir);
			}
			tv.appendChild(extParentDir);
		}
		//
		var mcrDir = TreeView.makeDir("Macros", "macros/");
		var mcrItems = mcrDir.querySelector(".items");
		mcrItems.appendChild(TreeView.makeItem("All configurations", "Configs/default", path, "config"));
		for (configs in gmx.findAll("Configs")) {
			for (config in configs.findAll("Config")) {
				var configPath = config.text;
				var configName = rxName.replace(configPath, "$1");
				var configFull = Path.join([dir, configPath + ".config.gmx"]);
				mcrItems.appendChild(TreeView.makeItem(configName, configPath, configFull, "config"));
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
				var next = new AceAutoCompleteItem(name, single);
				GmlAPI.gmlAssetComp.set(name, next);
				comp.push(next);
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
		GmlAPI.gmlKind = tm;
		//}
	}
}
