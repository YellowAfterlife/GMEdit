package gmx;
import gml.*;
import gml.file.*;
import ui.*;
import js.html.Element;
import haxe.io.Path;
import ace.AceWrap;
import ace.extern.*;
import parsers.GmlExtLambda;
import parsers.GmlSeeker;
import tools.Dictionary;
import tools.NativeString;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxLoader {
	public static var assetTypes:Array<String> = [
		"sprite", "background", "sound", "path", "font",
		"shader", "timeline", "script", "object", "room"
	];
	public static var rxAssetName:EReg = ~/^.+[\/\\](\w+)(?:\.[\w.]+)?$/g;
	public static var allConfigs:String = "All configurations";
	public static function run(project:Project) {
		var gmx = project.readGmxFileSync(project.name);
		//
		GmlSeeker.start();
		GmlAPI.gmlClear();
		var rxName = rxAssetName;
		TreeView.clear();
		var tv = TreeView.element;
		var ths = [];
		function loadrec(gmx:SfGmx, out:Element, one:String, path:String) {
			if (gmx.name == one) {
				var path = gmx.text;
				var name = rxName.replace(path, "$1");
				var full = project.fullPath(path);
				var _main:String = "";
				var kind:GmlFileKind = Normal;
				var index = true;
				switch (one) {
					case "script": _main = name;
					case "shader": { };
					default: {
						full += '.$one.gmx';
						switch (one) {
							case "sprite": kind = GmlFileKind.GmxSpriteView; index = false;
							case "object": kind = GmlFileKind.GmxObjectEvents;
							case "timeline": kind = GmlFileKind.GmxTimelineMoments;
						}
					};
				}
				GmlAPI.gmlLookupText += name + "\n";
				if (index) GmlSeeker.run(full, _main, kind);
				var item = TreeView.makeItem(name, path, full, one);
				if (one == "sprite") ths.push({path:full, item:item, name:name});
				out.appendChild(item);
				if (one == "shader") {
					kind = gmx.get("type").indexOf("HLSL") >= 0
						? GmlFileKind.HLSL : GmlFileKind.GLSL;
					item.setAttribute(TreeView.attrOpenAs, kind.getName());
				}
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
		function loadtop(one:String, ?plural:String):Void {
			if (plural == null) plural = one + "s";
			var dir = null;
			var pfx = NativeString.capitalize(plural) + "/";
			for (p in gmx.findAll(plural)) {
				if (dir == null) {
					dir = TreeView.makeDir(NativeString.capitalize(plural), pfx);
					tv.appendChild(dir);
				}
				for (q in p.children) {
					loadrec(q, dir.treeItems, one, pfx);
				}
			}
		}
		//
		loadtop("sprite");
		loadtop("script");
		loadtop("shader");
		loadtop("timeline");
		loadtop("object");
		for (th in ths) {
			TreeView.setThumb(th.path, project.getSpriteURL(th.name), th.item);
		}
		//
		function loadinc(gmx:SfGmx, out:Element, path:String) {
			if (gmx.name == "datafile") {
				var name = gmx.findText("name");
				var rel = Path.join(["datafiles", name]);
				var full = project.fullPath(Path.join([path, name]));
				var item = TreeView.makeItem(name, rel, full, "datafile") ;
				out.appendChild(item);
			} else {
				var name = gmx.get("name");
				var next = path + name + "/";
				var r = TreeView.makeDir(name, next);
				var c = r.treeItems;
				for (q in gmx.children) loadinc(q, c, next);
				out.appendChild(r);
			}
		}
		for (datafiles in gmx.findAll("datafiles")) {
			var parent = TreeView.makeDir("Included files", "Included files/");
			for (c in datafiles.children) loadinc(c, parent.treeItems, "datafiles/");
			if (parent.treeItems.children.length > 0) tv.appendChild(parent);
		}
		//
		GmlAPI.extClear();
		var comp = GmlAPI.gmlComp;
		project.lambdaMap = new Dictionary();
		var lz = ui.Preferences.current.lambdaMagic;
		for (extParent in gmx.findAll("NewExtensions")) {
			var extNodes = extParent.findAll("extension");
			if (extNodes.length == 0) continue;
			var extParentDir = TreeView.makeDir("Extensions", "Extensions/");
			for (extNode in extNodes) {
				var extRel = extNode.text;
				extRel = StringTools.replace(extRel, "\x5c", "/"); // no backslashes
				var extPath = extRel + ".extension.gmx";
				var extGmx = project.readGmxFileSync(extPath);
				var extName = extGmx.findText("name");
				var extDir = TreeView.makeDir(extName, "extensions/" + extName + "/");
				var lm = lz && extName.toLowerCase() == parsers.GmlExtLambda.extensionName ? project.lambdaMap : null;
				if (lm != null) project.lambdaExt = extPath;
				for (extFiles in extGmx.findAll("files"))
				for (extFile in extFiles.findAll("file")) {
					var extFileName = extFile.findText("filename");
					var isGmlFile = Path.extension(extFileName).toLowerCase() == "gml";
					var extFilePath = Path.join([extNode.text, extFileName]);
					var extFileFull = project.fullPath(extFilePath);
					extDir.treeItems.appendChild(TreeView.makeItem(
						extFileName, extFilePath, extFileFull, "extfile"
					));
					//
					if (isGmlFile) {
						if (lm != null) {
							project.lambdaGml = extFileFull;
							parsers.GmlExtLambda.readDefs(extFileFull);
						} else GmlSeeker.run(extFileFull, "", ExtGML);
					}
					//
					if (lm != null) {
						for (funcs in extFile.findAll("functions"))
						for (func in funcs.findAll("function")) {
							var ls = func.findText("name");
							ls = NativeString.replaceExt(ls, GmlExtLambda.rxlcPrefix, GmlExtLambda.lfPrefix);
							lm.set(ls, true);
						}
					} else for (funcs in extFile.findAll("functions"))
					for (func in funcs.findAll("function")) {
						var name = func.findText("name");
						GmlAPI.extKind.set(name, "extfunction");
						var help = func.findText("help");
						if (help != null && help != "") {
							GmlAPI.extCompAdd(new AceAutoCompleteItem(name, "function", help));
							GmlAPI.extDoc.set(name, GmlFuncDoc.parse(help));
							if (isGmlFile) GmlAPI.gmlLookupText += name + "\n";
						}
						if (isGmlFile) {
							GmlAPI.gmlLookup.set(name, {
								path: extFileFull,
								sub: name,
								row: 0,
							});
						}
					}
					//
					for (mcrs in extFile.findAll("constants"))
					for (mcr in mcrs.findAll("constant")) {
						var name = mcr.findText("name");
						GmlAPI.extKind.set(name, "extmacro");
						if (mcr.findText("hidden") == "0") {
							var expr = mcr.findText("value");
							GmlAPI.extCompAdd(new AceAutoCompleteItem(name, "macro", expr));
						}
					}
				} // for (extFile)
				if (extName == "GMLive" && GmlAPI.extKind.exists("live_init")) {
					project.hasGMLive = true;
				}
				extParentDir.treeItems.appendChild(extDir);
			}
			tv.appendChild(extParentDir);
		}
		//
		var mcrDir = TreeView.makeDir("Macros", "macros/");
		var mcrItems = mcrDir.querySelector(".items");
		mcrItems.appendChild(TreeView.makeItem(allConfigs, "Configs/default", project.fullPath(project.name), "config"));
		for (configs in gmx.findAll("Configs")) {
			for (config in configs.findAll("Config")) {
				var configPath = config.text;
				var configName = rxName.replace(configPath, "$1");
				var configFull = configPath + ".config.gmx";
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
				var cpath = confNode.text + ".config.gmx";
				var cgmx = project.readGmxFileSync(cpath);
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
