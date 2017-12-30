package gml;
import ace.AceSessionData;
import electron.FileSystem;
import js.RegExp;
import js.html.Element;
import ace.AceWrap;
import gmx.*;
import Main.document;
import haxe.io.Path;
import tools.Dictionary;
import tools.NativeString;
import tools.StringBuilder;
import yy.YyBase;
import yy.YyObject;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFile {
	public static var next:GmlFile = null;
	public static var current(default, set):GmlFile = null;
	//
	public var name:String;
	public var path:String;
	public var notePath(get, never):String;
	private inline function get_notePath():String {
		return path + ".gmlnotes";
	}
	public var code:String;
	public var kind:GmlFileKind = Normal;
	public var session:AceSession;
	public var tabEl:Element;
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
	//
	public function new(name:String, path:String, kind:GmlFileKind, ?data:Dynamic) {
		this.name = name;
		this.path = path;
		this.kind = kind;
		load(data);
		var modePath = switch (kind) {
			case SearchResults: "ace/mode/gml_search";
			default: "ace/mode/gml";
		}
		// todo: this does not seem to cache per-version, but not a performance hit either?
		session = new AceSession(code, { path: modePath, version: GmlAPI.version });
		session.setUndoManager(new AceUndoManager());
		session.gmlFile = this;
	}
	public function close():Void {
		AceSessionData.store(this);
	}
	//
	private static function openPost(file:GmlFile, nav:GmlFileNav) {
		var editor = Main.aceEditor;
		var session = file.session;
		var len = session.getLength();
		//
		var found = false;
		var row = 0, col = 0;
		var i:Int, s:String;
		if (nav.def != null) {
			var rxDef = new RegExp("^(#define|#event)[ \t]" + NativeString.escapeRx(nav.def));
			i = 0;
			while (i < len) {
				s = session.getLine(i);
				if (rxDef.test(s)) {
					row = i + 1;
					col = s.length;
					found = true;
					break;
				} else i += 1;
			}
		}
		var ctx = nav.ctx;
		if (ctx != null) {
			var rxCtx = new RegExp(NativeString.escapeRx(ctx));
			var rxEof = new RegExp("^(#define|#event)");
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
		var pos = nav.pos;
		if (pos != null) {
			if (ctx == null) col = 0;
			row += pos.row;
			col += pos.column;
			found = true;
		}
		if (found) {
			editor.gotoLine0(row, col);
		}
		/*switch (nav) {
			case Offset(p): editor.gotoPos(p);
			case Script(name, pos): {
				var session = file.session;
				var def = new js.RegExp("^(#define|#event)[ \t]" + name, "");
				for (row in 0 ... session.getLength()) {
					var line = session.getLine(row);
					if (def.test(line)) {
						if (pos != null) {
							var col = pos.column;
							var row1 = row + pos.row;
							if (col == null) {
								line = session.getLine(row1);
								col = line != null ? line.length : 0;
							}
							editor.gotoLine0(row1, col);
						} else editor.gotoLine0(row, line.length);
						break;
					}
				}
			};
		}*/
	}
	public static function open(name:String, path:String, ?nav:GmlFileNav):GmlFile {
		// see if there's an existing tab for this:
		for (tabEl in ui.ChromeTabs.element.querySelectorEls('.chrome-tab')) {
			var gmlFile:GmlFile = untyped tabEl.gmlFile;
			if (gmlFile != null && gmlFile.path == path) {
				tabEl.click();
				if (nav != null) Main.window.setTimeout(function() {
					openPost(gmlFile, nav);
				});
				return gmlFile;
			}
		}
		// determine what to do with the file:
		var kind:GmlFileKind;
		var ext = Path.extension(path).toLowerCase();
		var data:Dynamic = null;
		switch (ext) {
			case "gml": kind = Normal;
			case "gmx": {
				ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
				kind = switch (ext) {
					case "object": GmxObjectEvents;
					case "project": GmxProjectMacros;
					case "config": GmxConfigMacros;
					default: Extern;
				}
			};
			case "yy": {
				var json:YyBase = FileSystem.readJsonFileSync(path);
				switch (json.modelName) {
					case "GMObject": {
						data = json;
						kind = YyObjectEvents;
					}
					case "GMScript": {
						path = Path.withoutExtension(path) + ".gml";
						kind = Normal;
					}
					default: kind = Extern;
				};
			};
			default: kind = Extern;
		}
		//
		if (kind != Extern) {
			var file = new GmlFile(name, path, kind, data);
			AceSessionData.restore(file);
			// addTab doesn't return the new tab so we bind it up in the "active tab change" event:
			GmlFile.next = file;
			ui.ChromeTabs.addTab(name);
			Main.window.setTimeout(function() {
				Main.aceEditor.focus();
				if (nav != null) openPost(file, nav);
			});
			return file;
		} else {
			electron.Shell.openItem(path);
			return null;
		}
	}
	//
	public function load(?data:Dynamic) {
		var src:String = data != null ? null : FileSystem.readTextFileSync(path);
		var gmx:SfGmx, out:String, errors:String;
		switch (kind) {
			case Extern: code = data != null ? data : "";
			case SearchResults: code = data;
			case Normal: code = src;
			case GmxObjectEvents: {
				gmx = SfGmx.parse(src);
				out = GmxObject.getCode(gmx);
				if (out == null) {
					code = GmxObject.errorText;
				} else code = out;
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = SfGmx.parse(src);
				var notes = FileSystem.existsSync(notePath)
					? new GmlReader(FileSystem.readTextFileSync(notePath)) : null;
				code = GmxProject.getMacroCode(gmx, notes, kind == GmxConfigMacros);
			};
			case YyObjectEvents: {
				var obj:yy.YyObject = data;
				code = obj.getCode(path);
			};
		}
	}
	//
	public function save() {
		if (path == null) return;
		var val = session.getValue();
		//
		var out:String, src:String, gmx:SfGmx;
		switch (kind) {
			case Normal, Extern: out = val;
			case GmxObjectEvents: {
				gmx = FileSystem.readGmxFileSync(path);
				if (!GmxObject.updateCode(gmx, val)) {
					Main.window.alert("Can't update GMX:\n" + GmxObject.errorText);
					return;
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
					Main.window.alert("Can't update YY:\n" + YyObject.errorText);
					return;
				}
				out = haxe.Json.stringify(obj, null, "    ");
			};
			default: {
				return;
			};
		}
		//
		//session.setValue(out);
		FileSystem.writeFileSync(path, out);
		changed = false;
		session.getUndoManager().markClean();
		//
		if (current == this) {
			var data = GmlSeekData.map[path];
			if (data != null) {
				GmlSeeker.runSync(path, out, data.main);
				var next = GmlSeekData.map[path];
				if (next != data) {
					GmlLocals.currentMap = next.locals;
					Main.aceEditor.session.bgTokenizer.start(0);
				}
			}
		}
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
@:fakeEnum(Int) enum GmlFileKind {
	Extern;
	Normal;
	GmxObjectEvents;
	GmxProjectMacros;
	GmxConfigMacros;
	YyObjectEvents;
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
