package file;
import editors.EditCode;
import editors.Editor;
import electron.FileSystem;
import file.kind.*;
import file.kind.gml.*;
import file.kind.gmx.*;
import file.kind.yy.*;
import file.kind.misc.*;
import gml.file.GmlFile;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class FileKind {
	public static var map:Dictionary<Array<FileKind>> = new Dictionary();
	public static function register(fileExt:String, file:FileKind):Void {
		var arr = map[fileExt];
		if (arr == null) {
			arr = [];
			map.set(fileExt, arr);
		}
		arr.unshift(file);
	}
	//
	
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
			Main.console.error("Error checking " + path + ": ", e);
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
			Main.console.error("Error checking " + pair.path + ": ", e);
		}
		//
		return changed ? 1 : 0;
	}
	
	public static function initStatic():Void {
		register("gml", KGmlScript.inst);
		register("txt", KPlain.inst);
		register("shader", KGLSL.inst);
		register("vsh", KGLSL.inst);
		register("fsh", KGLSL.inst);
		//
		register("gmx", KGmx.inst);
		KGmx.register("object", KGmxEvents.inst);
		KGmx.register("timeline", KGmxMoments.inst);
		KGmx.register("project", new KGmxMacros(false));
		KGmx.register("config", new KGmxMacros(true));
		KGmx.register("sprite", KGmxSprite.inst);
		//
		register("yy", KYy.inst);
		KYy.register("GMObject", KYyEvents.inst);
		KYy.register("GMShader", KYyShader.inst);
		KYy.register("GMTimeline", KYyMoments.inst);
		KYy.register("GMScript", KGmlScript.inst);
		KYy.register("GMSprite", KYySprite.inst);
		//
		register("md", new KMarkdown(false));
		register("dmd", new KMarkdown(true));
		register("js", KJavaScript.inst);
	}
}
