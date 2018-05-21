package gml.file;
import ace.AceSnippets;
import electron.FileWrap;
import gml.file.GmlFile;
import electron.FileSystem;
import gmx.*;
import parsers.*;
import yy.*;
import ace.AceSessionData;
import haxe.Json;
import tools.NativeArray;
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
			: return file.path != null;
			default: return false;
		}
	}
	public static function load(file:GmlFile, data:Dynamic) {
		var src:String;
		if (data != null) {
			src = data;
		} else switch (file.kind) {
			case Multifile: src = "";
			case Snippets: src = AceSnippets.getText(file.path);
			default: src = FileWrap.readTextFileSync(file.path);
		}
		var gmx:SfGmx, out:String, errors:String;
		function setError(s:String) {
			file.code = s;
			file.path = null;
			file.kind = Extern;
		}
		switch (file.kind) {
			case Extern: file.code = data != null ? data : "";
			case YyShader: file.code = "";
			case Plain, GLSL, HLSL, JavaScript, Snippets: file.code = src;
			case SearchResults: file.code = data;
			case Normal: {
				src = GmlExtCoroutines.pre(src);
				src = GmlExtArgs.pre(src);
				file.code = src;
			};
			case Multifile: {
				if (data != null) file.multidata = data;
				NativeArray.clear(file.extraFiles);
				out = ""; errors = "";
				for (item in file.multidata) {
					if (out != "") out += "\n\n";
					out += "#define " + item.name + "\n";
					var itemCode = FileWrap.readTextFileSync(item.path);
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
					file.extraFiles.push(new GmlFileExtra(item.path));
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
				if (data == null) data = Json.parse(src);
				var obj:YyObject = data;
				NativeArray.clear(file.extraFiles);
				file.code = obj.getCode(file.path, file.extraFiles);
			};
			case GmxTimelineMoments: {
				gmx = SfGmx.parse(src);
				out = GmxTimeline.getCode(gmx);
				if (out != null) {
					file.code = out;
				} else setError(GmxObject.errorText);
			};
			case YyTimelineMoments: {
				if (data == null) data = Json.parse(src);
				var tl:YyTimeline = data;
				NativeArray.clear(file.extraFiles);
				file.code = tl.getCode(file.path, file.extraFiles);
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = SfGmx.parse(src);
				var notePath = file.notePath;
				var notes = FileWrap.existsSync(notePath)
					? new GmlReader(FileWrap.readTextFileSync(notePath)) : null;
				file.code = GmxProject.getMacroCode(gmx, notes, file.kind == GmxConfigMacros);
			};
		}
		file.syncTime();
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
		GmlFileBackup.save(file, val);
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
				if (out == null) return error("Can't process macro:\n" + GmlExtArgs.errorText);
				if (ui.Preferences.current.argsFormat != null) {
					if (GmlExtArgsDoc.proc(file)) {
						out = file.session.getValue();
						out = GmlExtArgs.post(out);
						Main.window.setTimeout(function() {
							file.session.getUndoManager().markClean();
							file.changed = false;
						});
					}
				}
				out = GmlExtCoroutines.post(out);
				if (out == null) return error(GmlExtCoroutines.errorText);
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
						FileWrap.writeTextFileSync(itemPath, itemCode);
					} else errors += "Can't save script " + item.name
						+ " because it is not among the edited group.\n";
				}
				if (errors != "") error(errors);
			};
			case SearchResults: {
				if (file.searchData == null) return false;
				if (!file.searchData.save(file)) return false;
				file.changed = false;
				file.session.getUndoManager().markClean();
				writeFile = false;
				out = null;
			};
			case GmxObjectEvents: {
				gmx = FileWrap.readGmxFileSync(path);
				if (!GmxObject.setCode(gmx, val)) {
					return error("Can't update GMX:\n" + GmxObject.errorText);
				}
				out = gmx.toGmxString();
			};
			case YyObjectEvents: {
				var obj:YyObject = FileWrap.readJsonFileSync(path);
				if (!obj.setCode(path, val)) {
					return error("Can't update YY:\n" + YyObject.errorText);
				}
				out = NativeString.yyJson(obj);
			};
			case GmxTimelineMoments: {
				gmx = FileWrap.readGmxFileSync(path);
				if (!GmxTimeline.setCode(gmx, val)) {
					return error("Can't update GMX:\n" + GmxTimeline.errorText);
				}
				out = gmx.toGmxString();
			};
			case YyTimelineMoments: {
				var tl:YyTimeline = FileWrap.readJsonFileSync(path);
				if (!tl.setCode(path, val)) {
					return error("Can't update YY:\n" + YyTimeline.errorText);
				}
				out = NativeString.yyJson(tl);
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = FileWrap.readGmxFileSync(path);
				var notes = new StringBuilder();
				GmxProject.setMacroCode(gmx, val, notes, file.kind == GmxConfigMacros);
				var notePath = file.notePath;
				if (notes.length > 0) {
					FileWrap.writeTextFileSync(notePath, notes.toString());
				} else if (FileWrap.existsSync(notePath)) {
					FileWrap.unlinkSync(notePath);
				}
				out = gmx.toGmxString();
			};
			case Snippets: {
				AceSnippets.setText(path, val);
				writeFile = false;
				out = null;
			};
			default: return false;
		}
		//
		if (writeFile) FileWrap.writeTextFileSync(path, out);
		file.savePost(out);
		return true;
	}
	public static function checkChanges(file:GmlFile) {
		var path = file.path;
		if (file.kind == Snippets) return;
		if (file.kind != Multifile) {
			if (path == null || !haxe.io.Path.isAbsolute(path)) return;
			if (!FileSystem.existsSync(path)) return;
		}
		var changed = false;
		if (file.kind != GmlFileKind.Multifile) try {
			var time1 = FileSystem.statSync(path).mtimeMs;
			if (time1 > file.time) {
				file.time = time1;
				changed = true;
			}
		} catch (e:Dynamic) {
			trace("Error checking " + path + ": ", e);
		}
		for (pair in file.extraFiles) try {
			var ppath = pair.path;
			if (!haxe.io.Path.isAbsolute(ppath) || !FileSystem.existsSync(ppath)) continue;
			var time1 = FileSystem.statSync(ppath).mtimeMs;
			if (time1 > pair.time) {
				pair.time = time1;
				changed = true;
			}
		} catch (e:Dynamic) {
			trace("Error checking " + pair.path + ": ", e);
		}
		if (changed) try {
			var prev = file.code;
			file.load();
			if (prev == file.code) {
				// OK!
			} else if (!file.changed) {
				file.session.setValue(file.code);
			} else {
				function printSize(b:Float) {
					inline function toFixed(f:Float):String {
						return untyped f.toFixed(n, 2);
					}
					if (b < 10000) return b + "B";
					b /= 1024;
					if (b < 10000) return toFixed(b) + "KB";
					b /= 1024;
					if (b < 10000) return toFixed(b) + "MB";
					b /= 1024;
					return toFixed(b) + "GB";
				}
				var bt = electron.Dialog.showMessageBox({
					title: "File conflict for " + file.name,
					message: "Source file changed ("
						+ printSize(file.code.length)
						+ ") but you have unsaved changes ("
						+ printSize(file.session.getValue().length)
						+ "). What would you like to do?",
					buttons: ["Reload file", "Keep current", "Open changes in a new tab"],
					cancelId: 1,
				});
				switch (bt) {
					case 0: file.session.setValue(file.code);
					case 1: { };
					case 2: {
						var name1 = file.name + " <copy>";
						GmlFile.next = new GmlFile(name1, null, SearchResults, file.code);
						ui.ChromeTabs.addTab(name1);
					};
				}
			}
		} catch (e:Dynamic) {
			trace("Error applying changes: ", e);
		}
	}
}
