package gml.file;
import ace.AceSessionData;
import ace.extern.*;
import editors.*;
import electron.Dialog;
import electron.FileSystem;
import parsers.*;
import electron.FileWrap;
import file.FileKind;
import file.kind.gml.KGmlSearchResults;
import file.kind.yy.KYyEvents;
import js.lib.RegExp;
import js.html.Element;
import ace.AceWrap;
import gml.GmlAPI;
import gmx.*;
import Main.document;
import haxe.io.Path;
import parsers.GmlReader;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
import plugins.PluginEvents;
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
			if (kind.checkSelfForChanges) try {
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
	public var kind:FileKind;
	
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
	public function new(name:String, path:String, kind:FileKind, ?data:Dynamic) {
		this.name = name;
		this.path = path;
		this.kind = kind;
		//
		context = kind.getTabContext(this, data);
		kind.init(this, data);
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
		return kind.navigate(editor, nav);
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
		if (nav != null && nav.noExtern && Std.is(kind, file.kind.misc.KExtern)) {
			kind = file.kind.misc.KPlain.inst;
		}
		var data = kd.data;
		return kind.create(name, path, data, nav);
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
		if (path != null) {
			syncTime();
			markClean();
		}
		// re-index if needed:
		if (path != null && out != null && codeEditor != null && codeEditor.kind.indexOnSave) {
			var data = GmlSeekData.map[path];
			if (data != null) {
				if (Std.is(kind, KYyEvents)) {
					GmlSeeker.runYyObject(path, out, true);
				} else {
					GmlSeeker.runSync(path, out, data.main, kind);
				}
				if (GmlAPI.version == GmlVersion.live) liveApply();
				var next = GmlSeekData.map[path];
				if (codeEditor.locals != next.locals) {
					codeEditor.locals = next.locals;
					if (current == this) codeEditor.session.bgTokenizer.start(0);
				}
			}
		}
		// syntax check:
		if (path != null && current == this
			&& codeEditor != null && Std.is(codeEditor.kind, file.kind.KGml)
		) {
			var check = inline parsers.linter.GmlLinter.getOption((q)->q.onSave);
			if (check) parsers.linter.GmlLinter.runFor(codeEditor);
		}
		// notify plugins:
		PluginEvents.fileSave({file:this, code:out});
	}
	public function save() {
		return editor.save();
	}
	//
	public function liveApply() {
		var data = GmlSeekData.map[path];
		if (data != null) {
			var comp = Main.aceEditor.gmlCompleters;
			comp.gmlCompleter.items = data.compList;
			GmlAPI.gmlComp = data.compList;
			GmlAPI.gmlKind = data.kindMap;
			GmlAPI.gmlEnums = data.enumMap;
			GmlAPI.gmlDoc = data.docMap;
			comp.globalFullCompleter.items = data.globalFullComp;
			GmlAPI.gmlGlobalFullComp = data.globalFullComp;
			GmlAPI.gmlGlobalFullMap = data.globalFullMap;
			comp.globalCompleter.items = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldComp = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldMap = data.globalFieldMap;
			comp.instCompleter.items = data.instFieldComp;
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
		GmlExternAPI.gmlResetOnDefine = version.resetOnDefine() && !Std.is(kind, KGmlSearchResults.inst);
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
	?kind:FileKind,
	?showAtTop:Bool,
	/// Opens Extern files as Plain instead
	?noExtern:Bool,
}
