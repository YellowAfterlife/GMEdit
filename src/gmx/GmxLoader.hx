package gmx;

#if !gmedit.no_gmx
import gml.*;
import file.FileKind;
import file.kind.gml.*;
import file.kind.gmx.*;
import file.kind.misc.*;
import gml.file.*;
import ui.*;
import gmx.SfGmx;
import haxe.macro.Expr.Var;
import js.html.Element;
import haxe.io.Path;
import ace.AceWrap;
import ace.extern.*;
import synext.GmlExtLambda;
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
		var seekSoon = [];
		project.resourceTypes = new Dictionary();
		function loadrec(gmx:SfGmx, out:Element, one:String, path:String) {
			if (gmx.name == one) {
				var path = gmx.text;
				var name = rxName.replace(path, "$1");
				var full = project.fullPath(path);
				var _main:String = "";
				var kind:FileKind = KGmlScript.inst;
				var index = true;
				switch (one) {
					case "script": _main = name;
					case "shader": { };
					default: {
						full += '.$one.gmx';
						switch (one) {
							case "sprite": kind = KGmxSprite.inst; index = false;
							case "object": kind = KGmxEvents.inst;
							case "timeline": kind = KGmxMoments.inst;
						}
					};
				}
				project.setResourceTypeFromPath(path);
				GmlAPI.gmlLookupItems.push({value:name, meta:"asset." + one});
				if (index) seekSoon.push({ full: full, main: _main, kind: kind});
				var item = TreeView.makeAssetItem(name, path, full, one);
				if (one == "sprite") ths.push({path:full, item:item, name:name});
				out.appendChild(item);
				if (one == "shader") {
					item.yyOpenAs = gmx.get("type").indexOf("HLSL") >= 0 ? KHLSL.inst : KGLSL.inst;
				}
			} else {
				var name = gmx.get("name");
				if (out == tv) name = name.charAt(0).toUpperCase() + name.substring(1);
				var next = path + name + "/";
				var r = TreeView.makeAssetDir(name, next, one);
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
					dir = TreeView.makeAssetDir(NativeString.capitalize(plural), pfx, one);
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
		if (true) {
			var dir = TreeView.makeAssetDir("Rooms", "Rooms/", "room");
			tv.appendChild(dir);
			var ccs = TreeView.makeAssetItem("roomCreationCodes",
				project.name, project.path, "roomccs");
			ccs.removeAttribute(TreeView.attrThumb);
			ccs.yyOpenAs = KGmxRoomCCs.inst;
			//ccs.yyOrder = -1;
			dir.treeItems.appendChild(ccs);
		}
		for (rooms in gmx.findAll("rooms")) {
			var rm = gmx.find("room");
			if (rm != null) project.gmxFirstRoomName = rm.text;
		}
		for (th in ths) {
			TreeView.setThumb(th.path, project.getSpriteURL(th.name), th.item);
		}
		for (item in seekSoon) {
			GmlSeeker.run(item.full, item.main, item.kind);
		}
		//
		function loadinc(gmx:SfGmx, out:Element, path:String) {
			if (gmx.name == "datafile") {
				var name = gmx.findText("name");
				var rel = Path.join(["datafiles", name]);
				var full = project.fullPath(Path.join([path, name]));
				var item = TreeView.makeAssetItem(name, rel, full, "datafile") ;
				out.appendChild(item);
				GmlAPI.gmlLookup.set(rel, { path: full, row: 0 });
				GmlAPI.gmlLookupItems.push({value:rel, meta:"includedFile"});
			} else {
				var name = gmx.get("name");
				var next = path + name + "/";
				var r = TreeView.makeAssetDir(name, next, "datafile");
				var c = r.treeItems;
				for (q in gmx.children) loadinc(q, c, next);
				out.appendChild(r);
			}
		}
		for (datafiles in gmx.findAll("datafiles")) {
			var parent = TreeView.makeAssetDir("Included files", "Included files/", "datafile");
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
			var extParentDir = TreeView.makeAssetDir("Extensions", "Extensions/", "extension");
			for (extNode in extNodes) {
				var extRel = extNode.text;
				extRel = StringTools.replace(extRel, "\x5c", "/"); // no backslashes
				var extPath = extRel + ".extension.gmx";
				var extFull = project.fullPath(extPath);
				var extGmx = project.readGmxFileSync(extPath);
				var extName = extGmx.findText("name");
				//
				var extDir = TreeView.makeAssetDir(extName, "Extensions/" + extName + "/", "extension");
				extDir.treeFullPath = extFull;
				extDir.treeIdent = extName;
				//
				var lm = lz && extName.toLowerCase() == GmlExtLambda.extensionName ? project.lambdaMap : null;
				if (lm != null) project.lambdaExt = extPath;
				//
				for (extFiles in extGmx.findAll("files"))
				for (extFile in extFiles.findAll("file")) {
					var extFileName = extFile.findText("filename");
					var isGmlFile = Path.extension(extFileName).toLowerCase() == "gml";
					var extFilePath = Path.join([extNode.text, extFileName]);
					var extFileFull = project.fullPath(extFilePath);
					extDir.treeItems.appendChild(TreeView.makeAssetItem(
						extFileName, extFilePath, extFileFull, "extfile"
					));
					//
					if (isGmlFile) {
						if (lm != null) {
							project.lambdaGml = extFileFull;
							synext.GmlExtLambda.readDefs(extFileFull);
						} else GmlSeeker.run(extFileFull, "", KGmlExtension.inst);
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
						GmlAPI.extArgc[name] = func.findInt("argCount");
						var help = func.findText("help");
						if (help != null && help != "") {
							GmlAPI.extCompAdd(new AceAutoCompleteItem(name, "function", help));
							GmlAPI.extDoc.set(name, GmlFuncDoc.parse(help));
							if (isGmlFile) GmlAPI.gmlLookupItems.push({value:name, meta:"extfunction"});
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
		var mcrDir = TreeView.makeAssetDir("Macros", "macros/", "config");
		var mcrItems = mcrDir.querySelector(".items");
		mcrItems.appendChild(TreeView.makeAssetItem(allConfigs, "Configs/default", project.fullPath(project.name), "config"));
		for (configs in gmx.findAll("Configs")) {
			for (config in configs.findAll("Config")) {
				var configPath = config.text;
				var configName = rxName.replace(configPath, "$1");
				var configFull = configPath + ".config.gmx";
				mcrItems.appendChild(TreeView.makeAssetItem(configName, configPath, configFull, "config"));
			}
		}
		tv.appendChild(mcrDir);
		//
		if (project.existsSync("#import")) {
			var idir = TreeView.makeAssetDir("Imports", "#import/", "file");
			raw.RawLoader.loadDirRec(project, idir.treeItems, "#import");
			tv.appendChild(idir);
		}
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
#end
