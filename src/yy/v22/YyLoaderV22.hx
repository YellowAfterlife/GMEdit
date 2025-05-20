package yy.v22;
import ace.extern.*;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.Project;
import js.lib.RegExp;
import js.html.Console;
import synext.GmlExtLambda;
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
import yy.YyProjectResource;
import yy.v22.YyGUIDCollisionChecker;
using tools.NativeString;

/**
 * Loads project files for GMS <= 2.2
 * @author YellowAfterlife
 */
class YyLoaderV22 {
	private static var rxDatafiles = new RegExp("\\bdatafiles_yy([\\\\/])");
	public static function run(project:Project, yyProject:YyProject):String {
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
		var treeLocation = new Dictionary<String>(); // GUID -> where at
		//
		var cfdKey1 = new Dictionary<YyProjectResource>();
		var cfdKey2 = new Dictionary<YyProjectResource>();
		var cfdPath = new Dictionary<YyProjectResource>();
		function checkForDuplicates(map:Dictionary<YyProjectResource>, key:String, item:YyProjectResource):Void {
			if (map.exists(key)) {
				Console.error('Collision for $key!'
					+ ' GMS2 will not load the project unless you fix this.'
					+ ' Contenders:', map[key], item);
			} else map[key] = item;
		}
		//
		project.resourceTypes = new Dictionary();
		for (res in yyProject.resources) {
			var key = res.Key;
			var val = res.Value;
			var path = val.resourcePath;
			var type = val.resourceType;
			val.resourceName = rxName.replace(path, "$1");
			//
			checkForDuplicates(cfdKey1, key.toString().toLowerCase(), res);
			checkForDuplicates(cfdKey2, val.id.toString().toLowerCase(), res);
			checkForDuplicates(cfdKey2, StringTools.replace(val.resourcePath.toLowerCase(), "\\", "/"), res);
			//
			var expectedPathPrefix:String = switch (type) {
				case "GMScript": "scripts";
				case "GMSprite": "sprites";
				case "GMObject": "objects";
				case "GMRoom": "rooms";
				default: null;
			};
			if (expectedPathPrefix != null && !NativeString.startsWith(path, expectedPathPrefix)) {
				Console.warn('`$path` is marked as $type but is not in $expectedPathPrefix directory.'
					+ ' This suggests that your resource type might be mismatched.');
			}
			//
			resources.set(key, res);
			//
			if (val.resourceType == "GMFolder") {
				var view:YyView = try {
					project.readYyFileSync(val.resourcePath);
				} catch (x:Dynamic) {
					Console.error("Failed to load " + val.resourcePath);
					continue;
				};
				val.resourceName = view.folderName;
				if (view.isDefaultView) rootView = view;
				views.set(key, view);
				if (NativeString.endsWith(val.resourcePath, "-room.yy")) {
					var path = val.resourcePath;
					var slash = path.lastIndexOf("\\");
					if (slash < 0) slash = path.indexOf("/");
					roomViews.set(path.substring(slash + 1, path.length - 8), view);
				}
			} else {
				project.setResourceTypeFromPath(path);
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
		project.yyTextureGroups = new Array();
		var scriptLambdas = project.properties.lambdaMode == Scripts;
		if (scriptLambdas) {
			GmlExtLambda.seekData = new parsers.GmlSeekData(KGmlLambdas.inst);
			GmlExtLambda.seekPath = project.fullPath("#lambdas");
		}
		var lz = ui.Preferences.current.lambdaMagic;
		function loadrec(out:Element, view:YyView, path:String) {
			for (el in view.children) {
				var res = resources[el];
				if (res == null) continue;
				//
				var val = res.Value;
				var name:String, rel:String;
				var type = val.resourceType;
				//
				var treeLocPath = '`$path` (in ${view.id}.yy)';
				if (treeLocation.exists(el)) {
					Console.warn('Resource `$el` ('
						+ (type == "GMFolder" ? views[res.Key].folderName : val.resourcePath)
						+ ') exists in two places at once, $treeLocPath and `' + treeLocation[el]
						+ '`. This may cause GMS2 to remove your resource on load.'
					);
				} else treeLocation[el] = treeLocPath;
				//
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
					if (vdir == null) continue;
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
							var atype = type.fastSubStart(2).decapitalize();
							var aceType = "asset." + atype;
							GmlAPI.gmlKind.set(name, aceType);
							if (type != "GMScript") { // scripts have custom logic below
								GmlAPI.gmlLookupItems.push({value:name, meta:aceType});
							}
							var next = new AceAutoCompleteItem(name, atype);
							comp.push(next);
							GmlAPI.gmlAssetComp.set(name, next);
						};
						case "GMNotes": {
							var atype = type.fastSubStart(2).decapitalize();
							var aceType = "asset." + atype;
							GmlAPI.gmlLookupItems.push({value:name, meta:aceType});
						};
					}
					if (out == null) continue;
					switch (type) {
						case "GMScript": {
							full = Path.withoutExtension(full) + ".gml";
							// we'll index lambda scripts on demand
							if (!scriptLambdas || !NativeString.startsWith(name, GmlExtLambda.lfPrefix)) {
								GmlAPI.gmlLookupItems.push({value:name, meta:"asset.script"});
								GmlSeeker.run(full, name, KGmlScript.inst);
							}
						};
						case "GMObject": {
							objectNames.set(res.Key, name);
							objectGUIDs.set(name, res.Key);
							GmlSeeker.run(full, null, KYyEvents.inst);
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
							GmlAPI.gmlLookup.set(rel, { path: full, row: 0 });
							GmlAPI.gmlLookupItems.push({value:name, meta:"includedFile"});
						};
						case "GMExtension": {
							var ext:YyExtension = FileWrap.readYyFileSync(full);
							var extDir = Path.directory(full);
							var extRel = path + ext.name + "/";
							var extEl = TreeView.makeAssetDir(ext.name, extRel, "extension");
							extEl.setAttribute(TreeView.attrPath, full);
							extEl.setAttribute(TreeView.attrIdent, ext.name);
							extEl.setAttribute(TreeView.attrYYID, res.Key);
							var lm = lz && ext.name.toLowerCase() == synext.GmlExtLambda.extensionName ? project.lambdaMap : null;
							if (lm != null) project.lambdaExt = full;
							var extColCheck = new YyGUIDCollisionChecker("extension", ext.name);
							for (file in ext.files) {
								var fileName = file.filename;
								var isGmlFile = Path.extension(fileName).toLowerCase() == "gml";
								var filePath = Path.join([extDir, fileName]);
								var fileItem = TreeView.makeAssetItem(
									fileName, extRel + fileName, filePath, "extfile"
								);
								extEl.treeItems.appendChild(fileItem);
								//
								extColCheck.add(file.id, "file", file.filename);
								var fileColCheck = new YyGUIDCollisionChecker("extension", ext.name, "file", file.filename);
								//
								if (isGmlFile) {
									if (lm != null) {
										project.lambdaGml = filePath;
										synext.GmlExtLambda.readDefs(filePath);
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
									fileColCheck.add(func.id, "function", name);
									GmlAPI.extKind.set(name, "extfunction");
									GmlAPI.extArgc[name] = func.argCount < 0 ? func.argCount : func.args.length;
									if (help != null && help != "" && !func.hidden) {
										GmlAPI.extCompAdd(new AceAutoCompleteItem(
											name, "function", help
										));
										GmlAPI.extDoc.set(name, gml.GmlFuncDoc.parse(help));
										if (isGmlFile) GmlAPI.gmlLookupItems.push({value:name, meta:"extfunction"});
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
									fileColCheck.add(mcr.id, "macro", name);
									if (name.indexOf("/*") >= 0) continue;
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
						case "GMSprite": { // fetch thumbnail and validate
							var spritePath = res.Value.resourcePath;
							project.readYyFile(spritePath, function(e, sprite:YySprite) {
								var url:String;
								if (e == null && sprite.frames != null) {
									// fetch first frame URL:
									var frame = sprite.frames[0];
									if (frame != null) {
										var fid = frame.id;
										var spriteDir = Path.directory(spritePath);
										var framePath = spriteDir + "/" + fid + ".png";
										url = project.getImageURL(framePath);
									} else url = null;
									
									// validate for frame ID collisions
									var found = new Dictionary<Int>();
									for (i => frame in sprite.frames) {
										var fid = frame.id;
										if (found.exists(fid)) {
											Console.error('GUID $fid (frame $i)'
												+ ' is already being used by frame ' + found[fid]
												+ ' in sprite ' + sprite.name
												+ '! GMS2 IDE may decline to load your project.'
											);
										} else found[fid] = i;
									}
								} else url = null;
								project.yySpriteURLs[res.Key] = url;
								TreeView.setThumb(full, url, item);
							});
						};
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
		// restoreOpen runs in Project:reload
		return null;
	}
}
