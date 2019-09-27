package yy;
import ace.extern.*;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.Project;
import js.lib.RegExp;
import parsers.GmlExtLambda;
import parsers.GmlSeeker;
import haxe.io.Path;
import js.html.Element;
import tools.Dictionary;
import tools.ExecQueue;
import tools.NativeString;
import ui.treeview.TreeView;
import file.kind.gml.*;
import file.kind.yy.*;
import file.kind.misc.*;

/**
 * ...
 * @author YellowAfterlife
 */
class YyLoader {
	private static var rxDatafiles = new RegExp("\\bdatafiles_yy([\\\\/])");
	public static function run(project:Project):String {
		var yyProject:YyProject = project.readJsonFileSync(project.name);
		var resources:Dictionary<YyProjectResource> = new Dictionary();
		project.yyResources = resources;
		var resourceGUIDs = new Dictionary<YyGUID>();
		project.yyResourceGUIDs = resourceGUIDs;
		//
		project.yySpriteURLs = new Dictionary();
		var views:Dictionary<YyView> = new Dictionary();
		var roomViews:Dictionary<YyView> = new Dictionary();
		var rootView:YyView = null;
		var rxName = Project.rxName;
		for (res in yyProject.resources) {
			var key = res.Key;
			var val = res.Value;
			val.resourceName = rxName.replace(val.resourcePath, "$1");
			if (resources.exists(key)) {
				Main.console.error('Resource ID collision for $key!'
					+ '\nFirst path: ' + resources[key].Value.resourcePath
					+ '\nSecond path: ' + val.resourcePath
					+ '\nGMS2 will deny to load your project unless you fix this.');
			}
			resources.set(key, res);
			if (val.resourceType == "GMFolder") {
				var view:YyView = project.readJsonFileSync(val.resourcePath);
				val.resourceName = view.folderName;
				if (view.isDefaultView) rootView = view;
				views.set(key, view);
				if (NativeString.endsWith(val.resourcePath, "-room.yy")) {
					var path = val.resourcePath;
					var slash = path.lastIndexOf("\\");
					if (slash < 0) slash = path.indexOf("/");
					roomViews.set(path.substring(slash + 1, path.length - 8), view);
				}
			}
		}
		if (rootView == null) return "Couldn't find a top-level view in project.";
		//
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		var comp = GmlAPI.gmlComp;
		//
		var objectNames = new Dictionary<String>();
		var objectGUIDs = new Dictionary<YyGUID>();
		project.yyObjectNames = objectNames;
		project.yyObjectGUIDs = objectGUIDs;
		project.lambdaMap = new Dictionary();
		var scriptLambdas = project.properties.lambdaMode == Scripts;
		if (scriptLambdas) {
			GmlExtLambda.seekData = new parsers.GmlSeekData();
			GmlExtLambda.seekPath = project.fullPath("#lambdas");
		}
		var lz = ui.Preferences.current.lambdaMagic;
		function loadrec(out:Element, view:YyView, path:String) {
			for (el in view.children) {
				var res = resources[el];
				if (res == null) continue;
				var val = res.Value;
				var name:String, rel:String;
				var type = val.resourceType;
				function loadrec_dir(vdir:YyView, name:String) {
					if (out == null) {
						loadrec(out, vdir, null);
						return;
					}
					rel = path + name + "/";
					if (name == "#gmedit-lambda") {
						project.lambdaView = res.Value.resourcePath;
						for (id in vdir.children) {
							var res1 = resources[id];
							if (res1 == null) continue;
							project.lambdaMap.set(res1.Value.resourceName, true);
						}
					}
					var filter = vdir.filterType.substring(2).toLowerCase();
					var dir = TreeView.makeAssetDir(name, rel, filter);
					dir.setAttribute(TreeView.attrYYID, res.Key);
					var nextOut = dir.treeItems;
					if (path == "" && vdir.folderName == "rooms") {
						var ccs = TreeView.makeAssetItem("roomCreationCodes",
							project.name, project.path, "roomccs");
						ccs.removeAttribute(TreeView.attrThumb);
						ccs.yyOpenAs = file.kind.yy.KYyRoomCCs.inst;
						dir.treeItems.appendChild(ccs);
						// consume the room items:
						//nextOut = Main.document.createDivElement();
					}
					loadrec(nextOut, vdir, rel);
					out.appendChild(dir);
				}
				if (type == "GMFolder") {
					var vdir = views[res.Key];
					name = vdir.folderName;
					if (path == "") switch (name) {
						case "datafiles": name = "Included Files";
						default: {
							name = name.charAt(0).toUpperCase() + name.substring(1);
						};
					}
					loadrec_dir(vdir, name);
				}
				else {
					name = val.resourceName;
					rel = path + name;
					var full = project.fullPath(val.resourcePath);
					resourceGUIDs.set(name, res.Key);
					switch (type) {
						case "GMSprite", "GMTileSet", "GMSound", "GMPath",
						"GMScript", "GMShader", "GMFont", "GMTimeline",
						"GMObject", "GMRoom": {
							var atype = type.substring(2).toLowerCase();
							GmlAPI.gmlKind.set(name, "asset." + atype);
							var next = new AceAutoCompleteItem(name, atype);
							comp.push(next);
							GmlAPI.gmlAssetComp.set(name, next);
						};
					}
					if (out == null) continue;
					switch (type) {
						case "GMScript": {
							GmlAPI.gmlLookupText += name + "\n";
							full = Path.withoutExtension(full) + ".gml";
							// we'll index lambda scripts on demand
							if (!scriptLambdas || !NativeString.startsWith(name, GmlExtLambda.lfPrefix)) {
								GmlSeeker.run(full, name, KGmlScript.inst);
							}
						};
						case "GMObject": {
							GmlAPI.gmlLookupText += name + "\n";
							objectNames.set(res.Key, name);
							objectGUIDs.set(name, res.Key);
							GmlSeeker.run(full, null, KYyEvents.inst);
						};
						case "GMShader": {
							GmlAPI.gmlLookupText += name + "\n";
							//full = Path.directory(full);
						};
						case "GMTimeline": {
							GmlAPI.gmlLookupText += name + "\n";
						};
						case "GMNotes": {
							rel = Path.withoutExtension(rel);
							var nx = Path.withoutExtension(full);
							full = nx + ".txt";
							name = Path.withoutDirectory(nx);
						};
						case "GMIncludedFile": {
							rel = Path.withoutExtension(rel);
							full = NativeString.replaceExt(full, rxDatafiles, "datafiles$1");
							full = Path.withoutExtension(full);
							name = Path.withoutDirectory(full);
						};
						case "GMExtension": {
							var ext:YyExtension = FileWrap.readJsonFileSync(full);
							var extDir = Path.directory(full);
							var extRel = path + ext.name + "/";
							var extEl = TreeView.makeAssetDir(ext.name, extRel, "extension");
							extEl.setAttribute(TreeView.attrPath, full);
							extEl.setAttribute(TreeView.attrIdent, ext.name);
							extEl.setAttribute(TreeView.attrYYID, res.Key);
							var lm = lz && ext.name.toLowerCase() == parsers.GmlExtLambda.extensionName ? project.lambdaMap : null;
							if (lm != null) project.lambdaExt = full;
							for (file in ext.files) {
								var fileName = file.filename;
								var isGmlFile = Path.extension(fileName).toLowerCase() == "gml";
								var filePath = Path.join([extDir, fileName]);
								var fileItem = TreeView.makeAssetItem(
									fileName, extRel + fileName, filePath, "extfile"
								);
								extEl.treeItems.appendChild(fileItem);
								//
								if (isGmlFile) {
									if (lm != null) {
										project.lambdaGml = filePath;
										parsers.GmlExtLambda.readDefs(filePath);
									} else {
										GmlSeeker.run(filePath, "", KGmlExtension.inst);
									}
									fileItem.yyOpenAs = KGmlExtension.inst;
								}
								//
								if (lm != null) {
									for (func in file.functions) {
										lm.set(NativeString.replaceExt(func.name, GmlExtLambda.rxlcPrefix, GmlExtLambda.lfPrefix), true);
									}
								} else for (func in file.functions) {
									var name = func.name;
									var help = func.help;
									GmlAPI.extKind.set(name, "extfunction");
									GmlAPI.extArgc[name] = func.argCount < 0 ? func.argCount : func.args.length;
									if (help != null && help != "" && !func.hidden) {
										GmlAPI.extCompAdd(new AceAutoCompleteItem(
											name, "function", help
										));
										GmlAPI.extDoc.set(name, gml.GmlFuncDoc.parse(help));
										if (isGmlFile) GmlAPI.gmlLookupText += name + "\n";
									}
									if (isGmlFile) {
										GmlAPI.gmlLookup.set(name, {
											path: filePath,
											sub: name,
											row: 0,
										});
									}
								}
								for (mcr in file.constants) {
									var name = mcr.constantName;
									GmlAPI.extKind.set(name, "extmacro");
									if (!mcr.hidden) {
										var expr = mcr.value;
										GmlAPI.extCompAdd(new AceAutoCompleteItem(
											name, "macro", expr
										));
									}
								}
							} // for file
							//
							for (extMisc in ["AndroidSource", "iOSSource"]) {
								var extMiscRel = rel + "/" + extMisc;
								if (project.existsSync(extMiscRel)) {
									var extMiscEl = TreeView.makeAssetDir(extMisc, extMiscRel, "file");
									raw.RawLoader.loadDirRec(project, extMiscEl.treeItems, extMiscRel);
									extEl.treeItems.appendChild(extMiscEl);
								}
							}
							//
							if (ext.name == "GMLive" && GmlAPI.extKind.exists("live_init")) {
								project.hasGMLive = true;
							}
							out.appendChild(extEl);
							continue;
						};
						default: {
							// nothing particular
						};
					}
					var kind = type.substring(2).toLowerCase(); // GMScript -> script
					var item = TreeView.makeAssetItem(name, rel, full, kind);
					item.setAttribute(TreeView.attrYYID, res.Key);
					// a thumbnail if we may:
					if (ui.Preferences.current.assetThumbs)
					switch (type) {
						case "GMSprite": TreeView.setThumbSprite(full, name, item);
					}
					//
					out.appendChild(item);
					if (type == "GMRoom") { // child rooms?
						var vdir:YyView = roomViews[res.Key];
						if (vdir != null) {
							loadrec_dir(vdir, name);
						}
					}
				}
			}
		}
		TreeView.saveOpen();
		TreeView.clear();
		loadrec(TreeView.element, rootView, "");
		if (project.existsSync("#import")) {
			var idir = TreeView.makeAssetDir("Imports", "#import/", "file");
			raw.RawLoader.loadDirRec(project, idir.treeItems, "#import");
			TreeView.element.appendChild(idir);
		}
		TreeView.restoreOpen();
		//
		return null;
	}
}
