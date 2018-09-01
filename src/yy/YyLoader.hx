package yy;
import ace.AceWrap.AceAutoCompleteItem;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.Project;
import js.RegExp;
import parsers.GmlSeeker;
import haxe.io.Path;
import js.html.Element;
import tools.Dictionary;
import tools.NativeString;
import ui.treeview.TreeView;

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
		var views:Dictionary<YyView> = new Dictionary();
		var rootView:YyView = null;
		for (res in yyProject.resources) {
			var key = res.Key;
			resources.set(key, res);
			var val = res.Value;
			if (val.resourceType == "GMFolder") {
				var view:YyView = project.readJsonFileSync(val.resourcePath);
				if (view.isDefaultView) rootView = view;
				views.set(key, view);
			}
		}
		if (rootView == null) return "Couldn't find a top-level view in project.";
		//
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		var comp = GmlAPI.gmlComp;
		//
		var rxName = Project.rxName;
		var objectNames = new Dictionary<String>();
		var objectGUIDs = new Dictionary<YyGUID>();
		project.yyObjectNames = objectNames;
		project.yyObjectGUIDs = objectGUIDs;
		project.lambdaMap = new Dictionary();
		var lz = ui.Preferences.current.lambdaMagic;
		function loadrec(out:Element, view:YyView, path:String) {
			for (el in view.children) {
				var res = resources[el];
				if (res == null) continue;
				var val = res.Value;
				var name:String, rel:String;
				var type = val.resourceType;
				if (type == "GMFolder") {
					var vdir:YyView = views[res.Key];
					if (out == null) {
						loadrec(out, vdir, null);
						continue;
					}
					name = vdir.folderName;
					if (path == "") switch (name) {
						case"sprites",
							"objects", "shaders", "scripts", "extensions", "timelines": {
							name = name.charAt(0).toUpperCase() + name.substring(1);
						};
						case "datafiles": name = "Included Files";
						default: {
							loadrec(null, vdir, null);
							continue;
						};
					}
					rel = path + name + "/";
					var dir = TreeView.makeDir(name, rel);
					dir.setAttribute(TreeView.attrYYID, res.Key);
					loadrec(dir.treeItems, vdir, rel);
					out.appendChild(dir);
				}
				else {
					name = rxName.replace(val.resourcePath, "$1");
					rel = path + name;
					var full = project.fullPath(val.resourcePath);
					switch (type) {
						case "GMSprite", "GMTileSet", "GMSound", "GMPath",
						"GMScript", "GMShader", "GMFont", "GMTimeline",
						"GMObject", "GMRoom", "GMIncludedFile": {
							var atype = type.substring(2).toLowerCase();
							GmlAPI.gmlKind.set(name, "asset." + atype);
							var next = new AceAutoCompleteItem(name, atype);
							comp.push(next);
							GmlAPI.gmlAssetComp.set(name, next);
						};
					}
					if (out == null) continue;
					switch (type) {
						case "GMSprite": {
							
						};
						case "GMScript": {
							GmlAPI.gmlLookupText += name + "\n";
							full = Path.withoutExtension(full) + ".gml";
							GmlSeeker.run(full, name);
						};
						case "GMObject": {
							GmlAPI.gmlLookupText += name + "\n";
							objectNames.set(res.Key, name);
							objectGUIDs.set(name, res.Key);
							GmlSeeker.run(full, null);
						};
						case "GMShader": {
							GmlAPI.gmlLookupText += name + "\n";
							//full = Path.directory(full);
						};
						case "GMTimeline": {
							GmlAPI.gmlLookupText += name + "\n";
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
							var extEl = TreeView.makeDir(ext.name, extRel);
							extEl.setAttribute(TreeView.attrYYID, res.Key);
							var lm = lz && ext.name.toLowerCase() == parsers.GmlExtLambda.extensionName ? project.lambdaMap : null;
							if (lm != null) project.lambdaExt = full;
							for (file in ext.files) {
								var fileName = file.filename;
								var isGmlFile = Path.extension(fileName).toLowerCase() == "gml";
								var filePath = Path.join([extDir, fileName]);
								extEl.treeItems.appendChild(TreeView.makeItem(
									fileName, extRel + fileName, filePath, "extfile"
								));
								//
								if (isGmlFile) {
									if (lm != null) {
										project.lambdaGml = filePath;
										parsers.GmlExtLambda.readDefs(filePath);
									} else GmlSeeker.run(filePath, "");
								}
								//
								if (lm != null) {
									for (func in file.functions) {
										lm.set(func.name, true);
									}
								} else for (func in file.functions) {
									var name = func.name;
									var help = func.help;
									GmlAPI.extKind.set(name, "extfunction");
									if (help != null && help != "" && !func.hidden) {
										GmlAPI.extComp.push(new AceAutoCompleteItem(
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
										GmlAPI.extComp.push(new AceAutoCompleteItem(
											name, "macro", expr
										));
									}
								}
							}
							if (ext.name == "GMLive" && GmlAPI.extKind.exists("live_init")) {
								project.hasGMLive = true;
							}
							out.appendChild(extEl);
							continue;
						};
						default: continue;
					}
					var kind = type.substring(2).toLowerCase(); // GMScript -> script
					var item = TreeView.makeItem(name, rel, full, kind);
					item.setAttribute(TreeView.attrYYID, res.Key);
					out.appendChild(item);
				}
			}
		}
		TreeView.saveOpen();
		TreeView.clear();
		loadrec(TreeView.element, rootView, "");
		TreeView.restoreOpen();
		//
		return null;
	}
}
