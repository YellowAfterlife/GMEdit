package gml.file;
import tools.Aliases;
import tools.Aliases.GmlCode;
import ace.AceSessionData;
import ace.extern.*;
import editors.*;
import electron.Dialog;
import electron.FileSystem;
import parsers.*;
import parsers.GmlMultifile;
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
import synext.GmlExtCoroutines;
import tools.Dictionary;
import tools.NativeString;
import tools.StringBuilder;
import yy.*;
import ui.ChromeTabs.ChromeTab;
import ui.search.GlobalSeachData;
import ui.Preferences;
using tools.HtmlTools;

/**
 * Represents a single "file", which will usually be tied to a tab and has an editor tied to it.
 * Some editor types (e.g. object editor for GMS2+) may associate multiple files on disk with one tab.
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
	public var path:FullPath;
	
	/**
	 * If this file-tab represents multiple files that have to be checked for changes,
	 * this array indicates their paths and last-changed times.
	 */
	public var extraFiles:Array<GmlFileExtra> = [];
	
	/** Source file change time */
	public var time:Float = 0;
	public function syncTime() {
		#if !lwedit
		if (path != null && FileSystem.canSync && Path.isAbsolute(path)) {
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
	public var tabEl:ChromeTab;
	
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
	public var multidata:GmlMultifileData;
	
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
		var kind:FileKind, data:Dynamic;
		if (nav != null && nav.kind != null) {
			kind = nav.kind;
			data = null;
		} else {
			var kd = GmlFileKindTools.detect(path);
			kind = kd.kind;
			data = kd.data;
		}
		if ((kind is file.kind.misc.KExtern) && (
			!electron.Electron.isAvailable() || nav != null && nav.noExtern
		)) {
			kind = file.kind.misc.KPlain.inst;
		}
		return kind.create(name, path, data, nav);
	}
	public static function openTab(file:GmlFile) {
		file.editor.stateLoad();
		// addTab doesn't return the new tab so we bind it up in the "active tab change" event:
		GmlFile.next = file;
		ui.ChromeTabs.addTab(file.name);
	}
	public function rename(newName:String, newPath:String) {
		
		this.name = newName;
		this.path = newPath;
		//
		this.context = kind.getTabContext(this, {});

		if (this.tabEl != null) {
			this.tabEl.refresh();
		}
		
		PluginEvents.fileRename({ file: this });

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
	public function savePost_shared(out:String, isReload:Bool) {
		// re-index if needed:
		if (path != null && out != null
			&& codeEditor != null && (isReload || codeEditor.kind.indexOnSave)
		) {
			var data = GmlSeekData.map[path];
			if (data != null) {
				kind.index(path, out, data.main, true);
				
				if (GmlAPI.version.config.indexingMode == Local) liveApply();
				
				codeEditor.session.gmlScopes.updateOnSave();
				
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
			&& (cast codeEditor.kind:file.kind.KGml).canSyntaxCheck
		) {
			var check = inline parsers.linter.GmlLinter.getOption((q)->q.onSave);
			if (check) parsers.linter.GmlLinter.runFor(codeEditor);
		}
	}
	public function savePost(?out:String) {
		if (path != null) {
			syncTime();
			markClean();
		}
		savePost_shared(out, false);
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
			comp.gmlCompleter.items = data.comps.array;
			GmlAPI.gmlComp = data.comps.array;
			GmlAPI.gmlKind = data.kindMap;
			GmlAPI.gmlEnums = data.enums.map;
			GmlAPI.gmlDoc = data.docs.map;
			comp.globalFullCompleter.items = data.globalFullComp;
			GmlAPI.gmlGlobalFullComp = data.globalFullComp;
			GmlAPI.gmlGlobalFullMap = data.globalFullMap;
			comp.globalCompleter.items = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldComp = data.globalFieldComp;
			GmlAPI.gmlGlobalFieldMap = data.globalFields.map;
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
		GmlExternAPI.gmlResetOnDefine = version.resetOnDefine() && !Std.is(kind, KGmlSearchResults);
		if (version.config.indexingMode == Local) liveApply();
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
	
	/** Returns if the content exists on disk (or wherever it may be) or not */
	public function existsContent() : Bool {
		return FileWrap.existsSync(path);
	}

	/** Writes the given code to storage */
	public function writeContent(code:GmlCode):Bool {
		try {
			FileWrap.writeTextFileSync(path, code);
			return true;
		} catch (x) {
			Dialog.showWarning("Couldn't update " + name+ ":\n" + x);
			return false;
		}
	}

	/** Reads the code from storage */
	public function readContent() : GmlCode {
		return FileWrap.readTextFileSync(path);
	}

}
typedef GmlFileNav = {
	/** definition (script/event) */
	?def:String,
	/** row-column */
	?pos:AcePos,
	/** code to scroll to */
	?ctx:String,
	/** alt. */
	?ctxRx:RegExp,
	/** if set, looks for ctx after pos rather than ctx offset by pos */
	?ctxAfter:Bool,
	/** file kind override */
	?kind:FileKind,
	?showAtTop:Bool,
	/// Opens Extern files as Plain instead
	?noExtern:Bool,
}
