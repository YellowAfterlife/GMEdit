package gml.file;
import gml.file.GmlFile;
import electron.FileSystem;
import gmx.*;
import parsers.*;
import yy.*;
import ace.AceSessionData;
import tools.NativeString;
import tools.Dictionary;
import tools.StringBuilder;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFileIO {
	public static function canImport(file:GmlFile) {
		switch (file.kind) {
			case GmlFileKind.Normal,
				GmlFileKind.GmxObjectEvents, GmlFileKind.YyObjectEvents,
				GmlFileKind.GmxTimelineMoments, GmlFileKind.YyTimelineMoments
			: return true;
			default: return false;
		}
	}
	public static function load(file:GmlFile, data:Dynamic) {
		var src:String = data != null ? data : FileSystem.readTextFileSync(file.path);
		file.syncTime();
		var gmx:SfGmx, out:String, errors:String;
		function setError(s:String) {
			file.code = s;
			file.path = null;
			file.kind = Extern;
		}
		switch (file.kind) {
			case Extern: file.code = data != null ? data : "";
			case YyShader: file.code = "";
			case Plain, GLSL, HLSL, JavaScript: file.code = src;
			case SearchResults: file.code = data;
			case Normal: file.code = GmlExtArgs.pre(src);
			case Multifile: {
				file.multidata = data;
				out = ""; errors = "";
				for (item in file.multidata) {
					if (out != "") out += "\n\n";
					out += "#define " + item.name + "\n";
					var itemCode = FileSystem.readTextFileSync(item.path);
					var itemSubs = GmlMultifile.split(itemCode, item.name);
					if (itemSubs == null) {
						errors += "Can't open " + item.name
							+ " for editing: " + GmlMultifile.errorText + "\n";
					} else switch (itemSubs.length) {
						case 0: { };
						case 1: {
							var subCode = itemSubs[0].code;
							out += NativeString.trimRight(subCode);
						};
						default: errors += "Can't open " + item.name
							+ " for editing because it contains multiple scripts.\n";
					}
				}
				if (errors == "") {
					// (too buggy)
					//out = GmlExtArgs.pre(out);
					//out = GmlExtImport.pre(out, path);
					GmlSeeker.runSync(file.path, out, "");
					file.code = out;
				} else setError(errors);
			};
			case GmxObjectEvents: {
				gmx = SfGmx.parse(src);
				out = GmxObject.getCode(gmx);
				if (out != null) {
					file.code = out;
				} else setError(GmxObject.errorText);
			};
			case YyObjectEvents: {
				var obj:YyObject = data;
				file.code = obj.getCode(file.path);
			};
			case GmxTimelineMoments: {
				gmx = SfGmx.parse(src);
				out = GmxTimeline.getCode(gmx);
				if (out != null) {
					file.code = out;
				} else setError(GmxObject.errorText);
			};
			case YyTimelineMoments: {
				var tl:YyTimeline = data;
				file.code = tl.getCode(file.path);
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = SfGmx.parse(src);
				var notePath = file.notePath;
				var notes = FileSystem.existsSync(notePath)
					? new GmlReader(FileSystem.readTextFileSync(notePath)) : null;
				file.code = GmxProject.getMacroCode(gmx, notes, file.kind == GmxConfigMacros);
			};
		}
		if (canImport(file)) {
			file.code = GmlExtImport.pre(file.code, file.path);
		}
	}
	public static function save(file:GmlFile) {
		var val = file.session.getValue();
		var path = file.path;
		file.code = val;
		inline function error(s:String) {
			Main.window.alert(s);
			return false;
		}
		//
		if (canImport(file)) {
			var val_preImport = val;
			val = GmlExtImport.post(val, path);
			// if there are imports, check if we should be updating the code
			var data = path != null ? GmlSeekData.map[path] : null;
			if (data != null && data.imports != null || GmlExtImport.post_numImports > 0) {
				var next = GmlExtImport.pre(val, path);
				if (GmlFile.current == file) {
					if (data != null && data.imports != null) {
						GmlImports.currentMap = data.imports;
					} else GmlImports.currentMap = GmlImports.defaultMap;
				}
				if (next != val_preImport) {
					var sd = AceSessionData.get(file);
					var session = file.session;
					session.doc.setValue(next);
					AceSessionData.set(file, sd);
					Main.window.setTimeout(function() {
						var undoManager = session.getUndoManager();
						if (!ui.Preferences.current.allowImportUndo) {
							session.setUndoManager(undoManager);
							undoManager.reset();
						}
						undoManager.markClean();
						file.changed = false;
					});
				}
			}
		}
		//
		var out:String, src:String, gmx:SfGmx;
		var writeFile:Bool = path != null;
		switch (file.kind) {
			case Extern: out = val;
			case Plain, GLSL, HLSL, JavaScript: out = val;
			case Normal: {
				out = val;
				out = GmlExtArgs.post(out);
				if (out == null) {
					return error("Can't process macro:\n" + GmlExtArgs.errorText);
				}
			};
			case Multifile: {
				out = val;
				/*out = GmlExtArgs.post(out);
				if (out == null) {
					return error("Can't process macro:\n" + GmlExtArgs.errorText);
				}*/
				//
				writeFile = false;
				var next = GmlMultifile.split(out, "<detached code>");
				var map0 = new Dictionary<String>();
				for (item in file.multidata) map0.set(item.name, item.path);
				var errors = "";
				for (item in next) {
					var itemPath = map0[item.name];
					if (itemPath != null) {
						var itemCode = item.code;
						FileSystem.writeFileSync(itemPath, itemCode);
					} else errors += "Can't save script " + item.name
						+ " because it is not among the edited group.\n";
				}
				if (errors != "") error(errors);
			};
			case SearchResults: {
				if (file.searchData != null) {
					return file.searchData.save(file);
				} else return false;
			};
			case GmxObjectEvents: {
				gmx = FileSystem.readGmxFileSync(path);
				if (!GmxObject.setCode(gmx, val)) {
					return error("Can't update GMX:\n" + GmxObject.errorText);
				}
				out = gmx.toGmxString();
			};
			case YyObjectEvents: {
				var obj:YyObject = FileSystem.readJsonFileSync(path);
				if (!obj.setCode(path, val)) {
					return error("Can't update YY:\n" + YyObject.errorText);
				}
				out = haxe.Json.stringify(obj, null, "    ");
			};
			case GmxTimelineMoments: {
				gmx = FileSystem.readGmxFileSync(path);
				if (!GmxTimeline.setCode(gmx, val)) {
					return error("Can't update GMX:\n" + GmxTimeline.errorText);
				}
				out = gmx.toGmxString();
			};
			case YyTimelineMoments: {
				var tl:YyTimeline = FileSystem.readJsonFileSync(path);
				if (!tl.setCode(path, val)) {
					return error("Can't update YY:\n" + YyTimeline.errorText);
				}
				out = haxe.Json.stringify(tl, null, "    ");
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = FileSystem.readGmxFileSync(path);
				var notes = new StringBuilder();
				GmxProject.setMacroCode(gmx, val, notes, file.kind == GmxConfigMacros);
				var notePath = file.notePath;
				if (notes.length > 0) {
					FileSystem.writeFileSync(notePath, notes.toString());
				} else if (FileSystem.existsSync(notePath)) {
					FileSystem.unlinkSync(notePath);
				}
				out = gmx.toGmxString();
			};
			default: return false;
		}
		//
		if (writeFile) FileSystem.writeFileSync(path, out);
		file.savePost(out);
		return true;
	}
}
