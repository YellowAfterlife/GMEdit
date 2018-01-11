package gml;
import ace.AceGmlCompletion;
import ace.AceSessionData;
import electron.Dialog;
import electron.FileSystem;
import gml.GmlMultifile;
import js.RegExp;
import js.html.Element;
import ace.AceWrap;
import gml.GmlAPI;
import gmx.*;
import Main.document;
import haxe.io.Path;
import tools.Dictionary;
import tools.NativeString;
import tools.StringBuilder;
import yy.*;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFile {
	public static var next:GmlFile = null;
	public static var current(default, set):GmlFile = null;
	private static var searchId:Int = 0;
	
	/** Display name (used for tab title). Usually name.ext */
	public var name:String;
	
	/** Full path to the source file (null if no source file, e.g. search results) */
	public var path:String;
	
	/** Source file change time */
	public var time:Float = 0;
	public inline function syncTime() {
		if (path != null && kind != Multifile) try {
			time = FileSystem.statSync(path).mtimeMs;
		} catch (_:Dynamic) { }
	}
	
	/** Context (used for tagging tabs) */
	public var context:String;
	
	/** Path to .gmlnotes (used for GMS1 macros) */
	public var notePath(get, never):String;
	private inline function get_notePath():String {
		return path + ".gmlnotes";
	}
	
	/** Last loaded/saved code */
	public var code:String;
	
	/** Loading/saving mode of operation */
	public var kind:GmlFileKind = Normal;
	
	/** Code editing session (contains up to date code) */
	public var session:AceSession;
	
	/** Associated chrome tab */
	public var tabEl:Element;
	
	/** Whether there had been changes since opening the file (setting updates tab status) */
	public var changed(get, set):Bool;
	private var __changed:Bool = false;
	private inline function get_changed() {
		return __changed;
	}
	private function set_changed(z:Bool) {
		if (__changed != z) {
			__changed = z;
			if (z) {
				tabEl.classList.add("chrome-tab-changed");
			} else {
				tabEl.classList.remove("chrome-tab-changed");
			}
		}
		return z;
	}
	
	public var multidata:Array<{ name:String, path:String }>;
	
	//
	public function new(name:String, path:String, kind:GmlFileKind, ?data:Dynamic) {
		this.name = name;
		this.path = path;
		this.kind = kind;
		load(data);
		if (path != null) {
			context = path;
		} else if (kind == SearchResults) {
			context = name + "#" + (searchId++);
		} else context = name;
		var modePath = switch (this.kind) {
			case SearchResults: "ace/mode/gml_search";
			case Extern, Plain: "ace/mode/text";
			default: "ace/mode/gml";
		}
		//
		if (GmlAPI.version == GmlVersion.live) {
			GmlSeeker.runSync(path, code, null);
		}
		// todo: this does not seem to cache per-version, but not a performance hit either?
		session = new AceSession(code, { path: modePath, version: GmlAPI.version });
		session.setUndoManager(new AceUndoManager());
		session.setOption("newLineMode", "windows");
		session.gmlFile = this;
	}
	public function close():Void {
		AceSessionData.store(this);
	}
	//
	public function navigate(nav:GmlFileNav):Bool {
		var editor = Main.aceEditor;
		var len = session.getLength();
		//
		var found = false;
		var row = 0, col = 0;
		var i:Int, s:String;
		if (nav.def != null) {
			var rxDef = new RegExp("^(#define|#event|#moment)[ \t]" + NativeString.escapeRx(nav.def));
			i = 0;
			while (i < len) {
				s = session.getLine(i);
				if (rxDef.test(s)) {
					row = i;
					col = s.length;
					found = true;
					break;
				} else i += 1;
			}
		}
		//
		var ctx = nav.ctx;
		if (ctx != null) {
			var rxCtx = new RegExp(NativeString.escapeRx(ctx));
			var rxEof = new RegExp("^(#define|#event|#moment)");
			i = row;
			while (i < len) {
				s = session.getLine(i);
				if (rxEof.test(s)) break;
				var vals = rxCtx.exec(s);
				if (vals != null) {
					row = i;
					col = vals.index;
					found = true;
					break;
				} else i += 1;
			}
		}
		//
		var pos = nav.pos;
		if (pos != null) {
			if (ctx == null) { col = 0; row += 1; }
			row += pos.row;
			col += pos.column;
			found = true;
		}
		if (found) {
			editor.gotoLine0(row, col);
		}
		return found;
	}
	public static function getKind(path:String):{kind:GmlFileKind, data:Null<Dynamic>} {
		var ext = Path.extension(path).toLowerCase();
		var data:Dynamic = null;
		var kind:GmlFileKind;
		switch (ext) {
			case "gml": kind = Normal;
			case "shader", "vsh", "fsh": kind = Plain;
			case "gmx": {
				ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
				kind = switch (ext) {
					case "object": GmxObjectEvents;
					case "project": GmxProjectMacros;
					case "config": GmxConfigMacros;
					case "timeline": GmxTimelineMoments;
					default: Extern;
				}
			};
			case "yy": {
				var json:YyBase = FileSystem.readJsonFileSync(path);
				switch (json.modelName) {
					case "GMObject": {
						data = json;
						kind = YyObjectEvents;
					};
					case "GMShader": {
						kind = YyShader;
					};
					case "GMTimeline": {
						data = json;
						kind = YyTimelineMoments;
					};
					case "GMScript": {
						path = Path.withoutExtension(path) + ".gml";
						kind = Normal;
					};
					default: kind = Extern;
				};
			};
			default: kind = Extern;
		}
		return { kind: kind, data: data };
	}
	public static function open(name:String, path:String, ?nav:GmlFileNav):GmlFile {
		// see if there's an existing tab for this:
		for (tabEl in ui.ChromeTabs.element.querySelectorEls('.chrome-tab')) {
			var gmlFile:GmlFile = untyped tabEl.gmlFile;
			if (gmlFile != null && gmlFile.path == path) {
				tabEl.click();
				if (nav != null) Main.window.setTimeout(function() {
					gmlFile.navigate(nav);
				});
				return gmlFile;
			}
		}
		// determine what to do with the file:
		var kd = getKind(path);
		var kind = kd.kind;
		var data = kd.data;
		//
		switch (kind) {
			case Extern: {
				electron.Shell.openItem(path);
				return null;
			};
			case YyShader: {
				open(name + ".vsh", Path.withoutExtension(path) + ".vsh");
				open(name + ".fsh", Path.withoutExtension(path) + ".fsh");
				return null;
			};
			default: {
				var file = new GmlFile(name, path, kind, data);
				openTab(file);
				Main.window.setTimeout(function() {
					Main.aceEditor.focus();
					if (nav != null) file.navigate(nav);
				});
				return file;
			};
		}
	}
	public static function openTab(file:GmlFile) {
		if (file.path != null) AceSessionData.restore(file);
		// addTab doesn't return the new tab so we bind it up in the "active tab change" event:
		GmlFile.next = file;
		ui.ChromeTabs.addTab(file.name);
	}
	//
	/**
	 * Loads the current code
	 * @param	data	If provided, is used instead of reading from FS.
	 */
	public function load(?data:Dynamic) {
		var src:String = data != null ? null : FileSystem.readTextFileSync(path);
		syncTime();
		var gmx:SfGmx, out:String, errors:String;
		function setError(s:String) {
			code = s;
			path = null;
			kind = Extern;
		}
		switch (kind) {
			case Extern: code = data != null ? data : "";
			case YyShader: code = "";
			case Plain: code = src;
			case SearchResults: code = data;
			case Normal: {
				code = src;
				code = GmlExtArgs.pre(code);
			};
			case Multifile: {
				multidata = data;
				out = ""; errors = "";
				for (item in multidata) {
					if (out != "") out += "\n\n";
					out += "#define " + item.name + "\n";
					var itemCode = FileSystem.readTextFileSync(item.path);
					var itemSubs = GmlMultifile.split(itemCode, item.name);
					if (itemSubs == null) {
						errors += "Can't open " + item.name
							+ " for editing: " + GmlMultifile.errorText + "\n";
					} else switch (itemSubs.length) {
						case 0: { };
						case 1: out += NativeString.trimRight(GmlExtArgs.pre(itemSubs[0].code));
						default: errors += "Can't open " + item.name
							+ " for editing because it contains multiple scripts.\n";
					}
				}
				if (errors == "") {
					GmlSeeker.runSync(path, out, "");
					code = out;
				} else setError(errors);
			};
			case GmxObjectEvents: {
				gmx = SfGmx.parse(src);
				out = GmxObject.getCode(gmx);
				if (out != null) {
					code = out;
				} else setError(GmxObject.errorText);
			};
			case GmxTimelineMoments: {
				gmx = SfGmx.parse(src);
				out = GmxTimeline.getCode(gmx);
				if (out != null) {
					code = out;
				} else setError(GmxObject.errorText);
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = SfGmx.parse(src);
				var notes = FileSystem.existsSync(notePath)
					? new GmlReader(FileSystem.readTextFileSync(notePath)) : null;
				code = GmxProject.getMacroCode(gmx, notes, kind == GmxConfigMacros);
			};
			case YyObjectEvents: {
				var obj:YyObject = data;
				code = obj.getCode(path);
			};
			case YyTimelineMoments: {
				var tl:YyTimeline = data;
				code = tl.getCode(path);
			};
		}
	}
	//
	public function save() {
		if (path == null) return false;
		var val = session.getValue();
		code = val;
		inline function error(s:String) {
			Main.window.alert(s);
			return false;
		}
		//
		var out:String, src:String, gmx:SfGmx;
		var writeFile:Bool = true;
		switch (kind) {
			case Extern: out = val;
			case Plain: out = val;
			case Normal: {
				out = val;
				out = GmlExtArgs.post(out);
				if (out == null) {
					return error("Can't process macro:\n" + GmlExtArgs.errorText);
				}
			};
			case Multifile: {
				out = val;
				out = GmlExtArgs.post(out);
				if (out == null) {
					return error("Can't process macro:\n" + GmlExtArgs.errorText);
				}
				//
				writeFile = false;
				var next = GmlMultifile.split(out, "<detached code>");
				var map0 = new Dictionary<String>();
				for (item in multidata) map0.set(item.name, item.path);
				var errors = "";
				for (item in next) {
					var itemPath = map0[item.name];
					if (itemPath != null) {
						FileSystem.writeFileSync(itemPath, item.code);
					} else errors += "Can't save script " + item.name
						+ " because it is not among the edited group.\n";
				}
				if (errors != "") error(errors);
			};
			case GmxObjectEvents: {
				gmx = FileSystem.readGmxFileSync(path);
				if (!GmxObject.setCode(gmx, val)) {
					return error("Can't update GMX:\n" + GmxObject.errorText);
				}
				out = gmx.toGmxString();
			};
			case GmxTimelineMoments: {
				gmx = FileSystem.readGmxFileSync(path);
				if (!GmxTimeline.setCode(gmx, val)) {
					return error("Can't update GMX:\n" + GmxTimeline.errorText);
				}
				out = gmx.toGmxString();
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = FileSystem.readGmxFileSync(path);
				var notes = new StringBuilder();
				GmxProject.setMacroCode(gmx, val, notes, kind == GmxConfigMacros);
				if (notes.length > 0) {
					FileSystem.writeFileSync(notePath, notes.toString());
				} else if (FileSystem.existsSync(notePath)) {
					FileSystem.unlinkSync(notePath);
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
			case YyTimelineMoments: {
				var tl:YyTimeline = FileSystem.readJsonFileSync(path);
				if (!tl.setCode(path, val)) {
					return error("Can't update YY:\n" + YyTimeline.errorText);
				}
				out = haxe.Json.stringify(tl, null, "    ");
			};
			default: return false;
		}
		//
		if (writeFile) FileSystem.writeFileSync(path, out);
		syncTime();
		changed = false;
		session.getUndoManager().markClean();
		// update things if this is the active tab:
		if (current == this) {
			var data = GmlSeekData.map[path];
			if (data != null) {
				GmlSeeker.runSync(path, out, data.main);
				if (GmlAPI.version == GmlVersion.live) liveApply();
				var next = GmlSeekData.map[path];
				if (next != data) {
					GmlLocals.currentMap = next.locals;
					Main.aceEditor.session.bgTokenizer.start(0);
				}
			}
		}
		return true;
	}
	//
	public function liveApply() {
		var data = GmlSeekData.map[path];
		if (data != null) {
			AceGmlCompletion.gmlCompleter.items = data.comp;
			AceGmlCompletion.globalCompleter.items = data.globalFieldComp;
			GmlAPI.gmlComp = data.comp;
			GmlAPI.gmlKind = data.kind;
			GmlAPI.gmlEnums = data.enumMap;
			GmlAPI.gmlDoc = data.docMap;
			GmlAPI.gmlGlobalFieldComp = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldMap = data.globalFieldMap;
		}
	}
	public function checkChanges() {
		if (path != null && kind != Multifile) try {
			var time1 = FileSystem.statSync(path).mtimeMs;
			if (time1 > time) {
				time = time1;
				var prev = code;
				load();
				if (prev == code) {
					// OK!
				} else if (!changed) {
					session.setValue(code);
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
					var bt = Dialog.showMessageBox({
						title: "File conflict for " + name,
						message: "Source file changed ("
							+ printSize(code.length)
							+ ") but you have unsaved changes ("
							+ printSize(session.getValue().length)
							+ "). What would you like to do?",
						buttons: ["Reload file", "Keep current", "Open changes in a new tab"],
						cancelId: 1,
					});
					switch (bt) {
						case 0: session.setValue(code);
						case 1: { };
						case 2: {
							var name1 = name + " <copy>";
							GmlFile.next = new GmlFile(name1, null, SearchResults, code);
							ui.ChromeTabs.addTab(name1);
						};
					}
				}
			}
		} catch (e:Dynamic) {
			trace("Error checking: ", e);
		}
	}
	/** Executed when the code tab gains focus */
	public function focus() {
		checkChanges();
		var version = GmlAPI.version;
		GmlExternAPI.gmlResetOnDefine = version != GmlVersion.live && kind != SearchResults;
		if (version == GmlVersion.live) liveApply();
	}
	//
	private static function set_current(file:GmlFile) {
		current = file;
		var data = file != null ? GmlSeekData.map[file.path] : null;
		if (data != null) {
			GmlLocals.currentMap = data.locals;
		} else {
			GmlLocals.currentMap = GmlLocals.defaultMap;
		}
		return file;
	}
}
enum GmlFileKind {
	/** Marks things that cannot be opened in GMEdit itself */
	Extern;
	/** Plaintext - no highlighting */
	Plain;
	/** */
	Normal;
	/** */
	Multifile;
	GmxObjectEvents;
	GmxTimelineMoments;
	GmxProjectMacros;
	GmxConfigMacros;
	YyObjectEvents;
	YyTimelineMoments;
	YyShader;
	SearchResults;
}
typedef GmlFileNav = {
	/** definition (script/event) */
	?def:String,
	/** row-column */
	?pos:AcePos,
	/** code to scroll to */
	?ctx:String
}
