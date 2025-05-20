package file;
import ui.ChromeTabs;
import editors.EditCode;
import editors.Editor;
import electron.FileSystem;
import file.kind.*;
import file.kind.gml.*;
import file.kind.gmx.*;
import file.kind.yy.*;
import file.kind.misc.*;
import gml.file.GmlFile;
import gml.project.ProjectState.ProjectTabState;
import tools.Dictionary;
import ui.ChromeTabs.ChromeTab;
import js.html.Console;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class FileKind {
	public static var inst:FileKind = new FileKind();
	/** file extension -> handlers */
	public static var map:Dictionary<Array<FileKind>> = new Dictionary();

	/**
		Register a `FileKind` to handle files with the given extension. There may be multiple kinds
		registered for the same extension. To disambiguate, for a file extension which may have
		multiple content types, `FileKind.detect()` should be overridden.
	**/
	public static function register(fileExt:String, file:FileKind):Void {
		var arr = map[fileExt];
		if (arr == null) {
			arr = [];
			map.set(fileExt, arr);
		}
		arr.unshift(file);
	}

	/**
		De-register a `FileKind` as a handler for the given extension. This should be called on
		clean-up of a plugin which registers any file types.
	**/
	public static function deregister(fileExt:String, file:FileKind):Void {

		for (tab in ChromeTabs.getTabs()) {
			if (tab.gmlFile?.kind == file) {
				tab.closeButton.click();
			}
		}
		
		final arr = map[fileExt];

		if (arr == null) {
			Console.error('Tried to de-register a file kind for the extension "$fileExt", which has none registered.');
			return;
		}

		if (!arr.remove(file)) {
			Console.error('Tried to de-register file kind ${file.getName()} for the extension "$fileExt", of which it is not registered to.');
		}

	}
	
	public var checkSelfForChanges:Bool = true;
	
	//
	public function new() {
		//
	}
	
	public function getName():String {
		return Type.getClassName(Type.getClass(this));
	}
	public function getTabContext(file:GmlFile, data:Dynamic):String {
		if (file.path != null) return file.path;
		return file.name;
	}
	
	public function saveTabState(tab:ChromeTab):ProjectTabState {
		var path = tab.gmlFile.path;
		if (path == null) return null;
		var rel = gml.Project.current.relPath(path) ?? path;
		var ts:ProjectTabState = {};
		if (rel != path) {
			ts.relPath = rel;
		} else ts.fullPath = path;
		return ts;
	}
	
	public static var tabStateLoaders:Dictionary<Array<ProjectTabState->GmlFile>> = new Dictionary();
	public static function registerTabStateLoader(tabStateKind:String, fn:ProjectTabState-> GmlFile) {
		var arr = tabStateLoaders[tabStateKind];
		if (arr == null) {
			arr = [];
			tabStateLoaders[tabStateKind] = arr;
		}
		arr.unshift(fn);
	}
	
	/**
	 * 
	 * @return	created file or null
	 */
	public function create(name:String, path:String, data:Dynamic, nav:GmlFileNav):GmlFile {
		var file = new GmlFile(name, path, this, data);
		GmlFile.openTab(file);
		if (file.codeEditor != null) Main.window.setTimeout(function() {
			Main.aceEditor.focus();
			if (nav != null) file.navigate(nav);
		});
		return file;
	}
	
	/**
	 * Called by a GmlFile upon creation.
	 * Should assign the file.editor by least.
	 */
	public function init(file:GmlFile, data:Dynamic):Void {
		//
	}
	
	/**
	 * Inspect a path and return a FK pair if it matches this type.
	 * pair.data can be used for cases where you need to read the file to detect type (YY),
	 * being passed into the load function later.
	 */
	public function detect(path:String, data:Dynamic):FileKindDetect {
		return {kind:this,data:data};
	}
	
	/**
	 * 
	 * @return	0 (no change) / 1 (changes) / -1 (file deleted)
	 */
	public function checkForChanges(editor:Editor):Int {
		var file = editor.file;
		var path = file.path;
		//
		if (checkSelfForChanges) {
			if (path == null || !haxe.io.Path.isAbsolute(path)) return 0;
			if (!FileSystem.existsSync(path)) return -1;
		}
		//
		var changed = false;
		if (checkSelfForChanges) try {
			var time1 = FileSystem.statSync(path).mtimeMs;
			if (time1 > file.time) {
				file.time = time1;
				changed = true;
			}
		} catch (e:Dynamic) {
			Console.error("Error checking " + path + ": ", e);
		}
		//
		for (pair in file.extraFiles) try {
			var ppath = pair.path;
			if (!haxe.io.Path.isAbsolute(ppath) || !FileSystem.existsSync(ppath)) continue;
			var time1 = FileSystem.statSync(ppath).mtimeMs;
			if (time1 > pair.time) {
				pair.time = time1;
				changed = true;
			}
		} catch (e:Dynamic) {
			Console.error("Error checking " + pair.path + ": ", e);
		}
		//
		return changed ? 1 : 0;
	}
	
	/**
	 * Ran by GmlSeeker.
	 * Should return whether done instantly (true)
	 * or will call GmlSeeker.runNext later itself (false).
	 * @param	path	Full (normal) or relative (ZIP) path to file
	 * @param	content	Raw file content (text/JSON)
	 * @param	sync	Whether operation should be performed synchronously/on-spot
	 */
	public function index(path:String, content:String, main:String, sync:Bool):Bool {
		return true;
	}
	
	/** We're asked to bring `nav` into view */
	public function navigate(editor:Editor, nav:GmlFileNav):Bool {
		return false;
	}
	
	public static function initStatic():Void {
		register("gml", KGmlScript.inst);
		register("txt", KPlain.inst);
		register("shader", KGLSL.inst);
		register("vsh", KGLSL.inst);
		register("fsh", KGLSL.inst);
		//
		#if !gmedit.no_gmx
		register("gmx", KGmx.inst);
		KGmx.register("object", KGmxEvents.inst);
		KGmx.register("timeline", KGmxMoments.inst);
		KGmx.register("project", new KGmxMacros(false));
		KGmx.register("config", new KGmxMacros(true));
		KGmx.register("sprite", KGmxSprite.inst);
		#end
		//
		register("yy", KYy.inst);
		KYy.register("GMObject", KYyEvents.inst);
		KYy.register("GMShader", KYyShader.inst);
		KYy.register("GMTimeline", KYyMoments.inst);
		KYy.register("GMScript", KGmlScript.inst);
		KYy.register("GMSprite", KYySprite.inst);
		KYy.register("GMExtension", KYyExtension.inst);
		KYy.register("GMFont", KYyFont.inst);
		KYy.register("GMSound", KYySound.inst);
		//
		register("md", new KMarkdown(false));
		register("dmd", new KMarkdown(true));
		register("js", KJavaScript.inst);
		register("json", KJavaScript.inst);
		//
		registerTabStateLoader(KPreferences.tabStateKind, KPreferences.loadTabState);
		registerTabStateLoader(KProjectProperties.tabStateKind, KProjectProperties.loadTabState);
	}
}
