package gml.file;
import ace.AceGmlCompletion;
import ace.AceSessionData;
import ace.extern.*;
import editors.*;
import electron.Dialog;
import electron.FileSystem;
import parsers.*;
import electron.FileWrap;
import js.RegExp;
import js.html.Element;
import ace.AceWrap;
import gml.GmlAPI;
import gmx.*;
import Main.document;
import haxe.io.Path;
import parsers.GmlReader;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
import shaders.ShaderHighlight;
import shaders.ShaderKind;
import tools.Dictionary;
import tools.NativeString;
import tools.StringBuilder;
import yy.*;
import ui.GlobalSeachData;
import ui.Preferences;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFile {
	public static var next:GmlFile = null;
	
	/** Currently active tab's file */
	public static var current(default, set):GmlFile = null;
	private static var searchId:Int = 0;
	
	/** Display name (used for tab title). Usually name.ext */
	public var name:String;
	
	/** Full path to the source file (null if no source file, e.g. search results) */
	public var path:String;
	
	/**
	 * If this file-tab represents multiple files that have to be checked for changes,
	 * this array indicates their paths and last-changed times.
	 */
	public var extraFiles:Array<GmlFileExtra> = [];
	
	/** Source file change time */
	public var time:Float = 0;
	public inline function syncTime() {
		#if !lwedit
		if (path != null && FileSystem.canSync) {
			if (kind != Multifile) try {
				time = FileSystem.statSync(path).mtimeMs;
			} catch (_:Dynamic) { }
			for (pair in extraFiles) try {
				pair.time = FileSystem.statSync(pair.path).mtimeMs;
			} catch (_:Dynamic) { }
		}
		#end
	}
	
	/** Context (used for tagging tabs) */
	public var context:String;
	
	/** Path to .gmlnotes (used for GMS1 macros) */
	public var notePath(get, never):String;
	private inline function get_notePath():String {
		return GmxProject.getNotePath(path);
	}
	
	/** Last loaded/saved code */
	public var code:String;
	
	/** Loading/saving mode of operation */
	public var kind:GmlFileKind = Normal;
	
	/** The associated editor */
	public var editor:Editor;
	
	/** Shortcut if this is a code editor. Otherwise null */
	public var codeEditor:EditCode;
	
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
	
	/** only for Multifle */
	public var multidata:Array<{ name:String, path:String }>;
	
	/** only for SearchResults */
	public var searchData:GlobalSeachData;
	
	//
	public function new(name:String, path:String, kind:GmlFileKind, ?data:Dynamic) {
		this.name = name;
		this.path = path;
		this.kind = kind;
		//
		if (path != null) {
			context = path;
		} else if (kind == SearchResults) {
			context = name + "#" + (searchId++);
		} else context = name;
		// determine how we're supposed to show this:
		var modePath = null;
		switch (kind) {
			case SearchResults: modePath = "ace/mode/gml_search";
			case Extern, Plain, Snippets: modePath = "ace/mode/text";
			case GLSL: ShaderHighlight.nextKind = GLSL; modePath = "ace/mode/shader";
			case HLSL: ShaderHighlight.nextKind = HLSL; modePath = "ace/mode/shader";
			case JavaScript: modePath = "ace/mode/javascript";
			case YySpriteView, GmxSpriteView: editor = new EditSprite(this);
			case Markdown, DocMarkdown: modePath = "ace/mode/markdown";
			default: modePath = "ace/mode/gml";
		}
		if (modePath != null) {
			codeEditor = new EditCode(this, modePath);
			editor = codeEditor;
		} else codeEditor = null;
		load(data);
		editor.ready();
	}
	public function close():Void {
		#if !lwedit
		editor.stateSave();
		editor.destroy();
		#else
		editor.destroy();
		GmlSeekData.remove(path);
		#end
	}
	//
	public function getAceSession():AceSession {
		return codeEditor != null ? codeEditor.session : null;
	}
	//
	public function navigate(nav:GmlFileNav):Bool {
		var session:AceSession = getAceSession();
		if (session == null) return false;
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
			if (nav.ctxAfter && nav.pos != null) i += nav.pos.row;
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
			if (ctx == null && nav.def != null) {
				col = 0;
				row += 1;
			}
			if (!found || !nav.ctxAfter) {
				row += pos.row;
				col += pos.column;
				found = true;
			}
		}
		if (found) {
			Main.aceEditor.gotoLine0(row, col);
		}
		return found;
	}
	public static function open(name:String, path:String, ?nav:GmlFileNav):GmlFile {
		path = Path.normalize(path);
		// todo: perhaps completely eliminate "name" from here and rely on file data
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
		var kd = GmlFileKindTools.detect(path);
		var kind = (nav != null && nav.kind != null) ? nav.kind : kd.kind;
		var data = kd.data;
		//
		switch (kind) {
			case Extern: {
				FileWrap.openExternal(path);
				return null;
			};
			case YyShader: {
				var shKind:GmlFileKind = switch (data.type) {
					case 2, 4: HLSL;
					default: GLSL;
				};
				var nav1:GmlFileNav = { kind: shKind };
				if (nav != null) {
					nav1.pos = nav.pos;
					nav1.ctx = nav.ctx;
				}
				var pathNx = Path.withoutExtension(path);
				if (nav != null) switch (nav.def) {
					case "vertex": return open(name + ".vsh", pathNx + ".vsh", nav1);
					case "fragment": return open(name + ".fsh", pathNx + ".fsh", nav1);
				}
				open(name + ".vsh", pathNx + ".vsh", nav1);
				open(name + ".fsh", pathNx + ".fsh", nav1);
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
		file.editor.stateLoad();
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
		editor.load(data);
	}
	//
	public function markClean() {
		changed = false;
		var q = getAceSession();
		if (q != null) q.getUndoManager().markClean();
	}
	//
	public function savePost(?out:String) {
		if (path == null) return;
		syncTime();
		markClean();
		// update things if this is the active tab:
		if (path != null && out != null && codeEditor != null) {
			var data = GmlSeekData.map[path];
			if (data != null) {
				switch (kind) {
					case GmlFileKind.YyObjectEvents: GmlSeeker.runYyObject(path, out, true);
					default: GmlSeeker.runSync(path, out, data.main, kind);
				}
				if (GmlAPI.version == GmlVersion.live) liveApply();
				var next = GmlSeekData.map[path];
				if (codeEditor.locals != next.locals) {
					codeEditor.locals = next.locals;
					if (current == this) codeEditor.session.bgTokenizer.start(0);
				}
			}
		}
	}
	public function save() {
		return editor.save();
	}
	//
	public function liveApply() {
		var data = GmlSeekData.map[path];
		if (data != null) {
			AceGmlCompletion.gmlCompleter.items = data.compList;
			GmlAPI.gmlComp = data.compList;
			GmlAPI.gmlKind = data.kindMap;
			GmlAPI.gmlEnums = data.enumMap;
			GmlAPI.gmlDoc = data.docMap;
			AceGmlCompletion.globalCompleter.items = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldComp = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldMap = data.globalFieldMap;
			AceGmlCompletion.instCompleter.items = data.instFieldComp;
			GmlAPI.gmlInstFieldComp = data.instFieldComp;
			GmlAPI.gmlInstFieldMap = data.instFieldMap;
		}
	}
	public function checkChanges() {
		editor.checkChanges();
	}
	/** Executed when the code tab gains focus */
	public function focus() {
		checkChanges();
		var version = GmlAPI.version;
		GmlExternAPI.gmlResetOnDefine = version.resetOnDefine() && kind != SearchResults;
		if (version == GmlVersion.live) liveApply();
	}
	//
	private static function set_current(file:GmlFile) {
		current = file;
		var data = file != null ? GmlSeekData.map[file.path] : null;
		var editor:EditCode = data != null && Std.is(file.editor, EditCode) ? (cast file.editor) : null;
		if (data != null) {
			GmlExtCoroutines.update(data.hasCoroutines);
		} else {
			GmlExtCoroutines.update(false);
		}
		return file;
	}
}
typedef GmlFileNav = {
	/** definition (script/event) */
	?def:String,
	/** row-column */
	?pos:AcePos,
	/** code to scroll to */
	?ctx:String,
	/** if set, looks for ctx after pos rather than ctx offset by pos */
	?ctxAfter:Bool,
	/** file kind override */
	?kind:GmlFileKind,
}
