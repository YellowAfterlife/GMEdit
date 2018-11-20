package ace;
import electron.FileSystem;
import electron.FileWrap;
import haxe.DynamicAccess;
import tools.Dictionary;
import ace.AceWrap;

/**
 * ...
 * @author YellowAfterlife
 */
class AceSnippets {
	static var langTools:AceLanguageTools;
	static var manager:AceSnippetManager;
	static var map:Dictionary<AceSnippetFile> = new Dictionary();
	static inline function getPath(mode:String):String {
		return "ace/snippets/" + mode;
	}
	public static function getText(mode:String) {
		var r:String = null;
		if (FileSystem.canSync) try {
			return FileSystem.readTextFileSync(FileWrap.userPath + "/snippets/" + mode + ".snippets");
		} catch (_:Dynamic) {}
		var r = Main.window.localStorage.getItem(getPath(mode));
		return r != null ? r : "";
	}
	public static function setText(mode:String, text:String):Void {
		if (FileSystem.canSync) {
			FileSystem.writeFileSync(FileWrap.userPath + "/snippets/" + mode + ".snippets", text);
		} else {
			Main.window.localStorage.setItem(getPath(mode), text);
		}
		reload(mode, text);
	}
	public static function reload(mode:String, ?text:String) {
		var file = map[mode];
		if (file != null) try {
			if (text == null) text = getText(mode);
			file.snippetText = text;
			file.snippets = manager.parseSnippetFile(text);
			manager.snippetMap.remove(mode);
			manager.snippetNameMap.remove(mode);
			manager.register(file.snippets, file.scope);
			return true;
		} catch (x:Dynamic) {
			Main.console.error("Couldn't refresh snippets:", x);
		}
		return false;
	}
	public static function init() {
		langTools = AceWrap.require("ace/ext/language_tools");
		manager = AceWrap.require("ace/snippets").snippetManager;
		for (mode in ["text", "gml", "gml_search", "shader"]) {
			AceWrap.define("ace/snippets/" + mode, [
				"require", "exports", "module",
			], function(require:AceRequire, exports:AceExports, module:AceModule) {
				var file:AceSnippetFile = exports;
				map.set(mode, file);
				file.snippetText = getText(mode);
				file.scope = mode;
			});
		}
		return langTools.snippetCompleter;
	}
}
extern class AceLanguageTools {
	public var textCompleter:Dynamic;
	public var keyWordCompleter:Dynamic;
	public var snippetCompleter:Dynamic;
	public function addCompleter(comp:Dynamic):Void;
}
extern class AceSnippetManager {
	public var snippetMap:DynamicAccess<Array<AceSnippetItem>>;
	public var snippetNameMap:DynamicAccess<DynamicAccess<AceSnippetItem>>;
	public var files:DynamicAccess<Dynamic>;
	public function parseSnippetFile(text:String):Array<AceSnippetItem>;
	public function register(snippets:Array<AceSnippetItem>, scope:String):Void;
}
extern class AceSnippetFile {
	public var snippetText:String;
	public var snippets:Array<AceSnippetItem>;
	public var scope:String;
}
extern class AceSnippetItem {
	
}
