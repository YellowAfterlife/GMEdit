package ace;
import ace.AceWrapCompleter;
import ace.extern.AceAutoCompleteCb;
import ace.extern.AceAutoCompleteItems;
import ace.extern.AcePos;
import ace.extern.AceSession;
import ace.extern.AceToken;
import ace.extern.AceTokenType;
import electron.FileSystem;
import electron.FileWrap;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import tools.Dictionary;
import ace.AceWrap;
import ace.extern.AceAutoCompleter;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class AceSnippets {
	static var langTools:AceLanguageTools;
	static var manager:AceSnippetManager;
	static var map:Dictionary<AceSnippetFile> = new Dictionary();
	public static var completer:AceAutoCompleter;
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
		completer = langTools.snippetCompleter;
	}
}
class AceSnippetCompleterProxy extends AceWrapCompleter {
	public var completer:AceAutoCompleter;
	
	public function new(
		completer:AceAutoCompleter,
		tokenFilterDictOrArray:EitherType<Dictionary<Bool>, Array<AceTokenType>>, not:Bool,
		modeFilter:AceSession->Bool
	) {
		this.completer = completer;
		super([], tokenFilterDictOrArray, not, modeFilter);
	}
	
	override public function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void {
		if (!ui.Preferences.current.compFilterSnippets || !modeFilter(session)) { // non-GML
			completer.getCompletions(editor, session, pos, prefix, callback);
			return;
		}
		//
		var tk:AceToken = session.getTokenAtPos(pos);
		var tkf:Bool = tokenFilter.exists(tk.type);
		if (!tkf && tokenFilterComment && tk.type.startsWith("comment")) tkf = true;
		if (tkf != tokenFilterNot) {
			completer.getCompletions(editor, session, pos, prefix, callback);
		} else callback(null, AceWrapCompleter.noItems);
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
