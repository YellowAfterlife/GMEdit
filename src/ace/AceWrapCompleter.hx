package ace;
import ace.AceGmlTools;
import ace.AceWrap;
import ace.extern.*;
import ace.extern.AceCommandManager;
import file.kind.misc.KGLSL;
import file.kind.misc.KHLSL;
import file.kind.gml.*;
import gml.GmlAPI;
import gml.GmlImports;
import gml.GmlNamespace;
import gml.GmlScopes;
import gml.file.GmlFile;
import haxe.extern.EitherType;
import js.lib.RegExp;
import parsers.GmlKeycode;
import parsers.GmlEvent;
import parsers.linter.GmlLinter;
import shaders.ShaderAPI;
import tools.Aliases;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceWrapCompleter implements AceAutoCompleter {
	public static var noItems(default, never):Array<AceAutoCompleteItem> = [];
	
	public var items:AceAutoCompleteItems;
	public var tokenFilter:Dictionary<Bool>;
	public var tokenFilterNot:Bool;
	public var tokenFilterComment:Bool;
	public var modeFilter:AceSession->Bool;
	public var minLength:Int = AceWrapCompleterMinLength.Default;
	public var dotKind:AceWrapCompleterDotKind = DKNone;
	/** Used for some dotKinds */
	public var dotKindMeta:Dynamic = null;
	public var colKind:AceWrapCompletionColKind = CKNone;
	public var identifierRegexps:Array<RegExp>;
	
	public function new(
		items:AceAutoCompleteItems,
		tokenFilterDictOrArray:EitherType<Dictionary<Bool>, Array<AceTokenType>>, not:Bool,
		modeFilterFunc:AceSession->Bool
	) {
		items.autoSort();
		identifierRegexps = [new RegExp("[_"+"a-z"+"A-Z"+"0-9"+"\\u00A2-\\uFFFF]")];
		this.items = items;
		if (Std.is(tokenFilterDictOrArray, Array)) { // legacy format
			tokenFilter = Dictionary.fromKeys(tokenFilterDictOrArray, true);
		} else tokenFilter = tokenFilterDictOrArray;
		tokenFilterComment = tokenFilter["comment"];
		tokenFilterNot = not;
		modeFilter = modeFilterFunc;
	}
	
	public static function checkColon(iter:AceTokenIterator) {
		// `var [some]:type`:
		var token = iter.stepBackward();
		if (token != null && token.type == "text") token = iter.stepBackward();
		if (token == null) return false;
		switch (token.type) {
			case "local", "sublocal", "localfield": {};
			case "eventname" if (token.value.startsWith("key")): return true;
			default: return false;
		}
		// `[var] some:type`:
		token = iter.stepBackward();
		if (token != null && token.type == "text") token = iter.stepBackward();
		if (token == null) return false;
		switch (token.value) {
			case "var", ",", "#args": {};
			case "(": {
				token = iter.stepBackward();
				if (token != null && token.type == "text") token = iter.stepBackward();
				if (token == null) return false;
				switch (token.type) {
					case "scriptname", "preproc.lambda": {};
					default: return false;
				}
			};
			default: return false;
		}
		return true;
	}
	
	inline function procMinLength():Int {
		switch (minLength) {
			case AceWrapCompleterMinLength.Default: {
				return ui.Preferences.current.compMatchMode == SectionStart ? 1 : 2;
			};
			default: return minLength;
		}
	}
	// interface AceAutoCompleter
	public function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void {
		inline function proc(show:Bool) {
			callback(null, show ? items : noItems);
		}
		var ml = procMinLength();
		if (prefix.length < ml || !modeFilter(session)) {
			proc(false);
			return;
		}
		if (editor.completer != null) {
			editor.completer.exactMatch = ui.Preferences.current.compExactMatch;
		}
		var tk:AceToken = session.getTokenAtPos(pos);
		if (colKind != CKNone) {
			if (tk != null && tk.type == "punctuation.operator" && tk.value.contains(":")) do { // once
				var iter = new AceTokenIterator(session, pos.row, pos.column);
				if (checkColon(iter)) switch (colKind) {
					case CKNamespaces: {
						var scope = session.gmlScopes.get(pos.row);
						if (scope == null) break;
						if (dotKindMeta) {
							callback(null, GmlAPI.gmlNamespaceComp.array);
						} else {
							var imp = GmlFile.current.codeEditor.imports[scope];
							if (imp == null) break;
							callback(null, imp.namespaceComp);
						}
					};
					case CKEnums: callback(null, GmlAPI.gmlEnumTypeComp);
					default: continue;
				}
				return;
			} while (false); // once
			proc(false);
			return;
		}
		else if (dotKind != DKNone) {
			do { // once
				if (tk == null) continue;
				var iter:AceTokenIterator = null;
				inline function initIter():AceTokenIterator {
					return new AceTokenIterator(session, pos.row, pos.column);
				}
				if (tk.type != "punctuation.operator" || !tk.value.contains(".")) {
					if (dotKind == DKEnum) {
						if (tk.type == "enumerror") {
							iter = initIter();
							tk = iter.stepBackward();
						}
					} else if (dotKind == DKGlobal) {
						if (tk.type == "globalfield") {
							iter = initIter();
							tk = iter.stepBackward();
						}
					}
				}
				if (tk.type != "punctuation.operator" || !tk.value.contains(".")) continue;
				
				var dotPos:AcePos;
				if (dotKind == DKSmart) {
					if (iter == null) iter = initIter();
					dotPos = iter.getCurrentTokenPosition();
				} else dotPos = null;
				
				if (editor.completer.eraseSelfDot) {
					tk = { type: "keyword", value: "self" };
				} else {
					if (iter == null) iter = initIter();
					tk = iter.stepBackward();
				}
				
				switch (dotKind) {
					case DKNamespace: { // NameSpace.staticField
						if (tk.type != "namespace") continue;
						var scope = session.gmlScopes.get(pos.row);
						if (scope == null) continue;
						var imp = GmlFile.current.codeEditor.imports[scope];
						var ns:GmlNamespace;
						if (dotKindMeta) {
							ns = GmlAPI.gmlNamespaces[tk.value];
						} else {
							if (imp == null) continue;
							ns = imp.namespaces[tk.value];
						}
						if (ns == null) continue;
						callback(null, ns.compStatic.array);
						return;
					};
					case DKSmart: {
						var scope = session.gmlScopes.get(pos.row);
						if (scope == null) continue;
						
						// some special cases where we know that we don't have to parse anything:
						var snip:GmlCode;
						switch (tk.type) {
							case "local", "sublocal", "asset.object", "namespace", "enum": {
								snip = tk.value;
							};
							case "keyword" if (tk.value == "self" || tk.value == "other"): snip = tk.value;
							default: {
								var from = AceGmlTools.skipDotExprBackwards(session, dotPos);
								snip = session.getTextRange(AceRange.fromPair(from, dotPos));
							}
						}
						
						var type = GmlLinter.getType(snip, session.gmlEditor, scope).type;
						if (type == null) continue;
						var isGlobal = dotKindMeta;
						if (isGlobal) editor.completer.getPopup().container.setAttribute("data-self-type", type);
						
						var isStatic = type.isType;
						if (isStatic) type = type.unwrapParam();
						
						var imp:GmlImports;
						if (!isGlobal) {
							imp = GmlFile.current.codeEditor.imports[scope];
							if (imp == null) continue;
						} else imp = null;
						
						var ns = dotKindMeta ? GmlAPI.gmlNamespaces[type] : imp.namespaces[type];
						if (ns != null) {
							callback(null, isStatic ? ns.compStatic.array : ns.getInstComp());
							return;
						} else if (!isGlobal) {
							var en = GmlAPI.gmlEnums[type];
							if (en == null) continue;
							callback(null, isStatic ? en.compList : en.fieldComp);
							return;
						}
					};
					case DKGlobal: { // global.variable
						proc(tk.value == "global");
					};
					case DKEnum: { // Enum.Construct
						if (tk.type != "enum") continue;
						var name = tk.value;
						// expand imports:
						var scope = session.gmlScopes.get(pos.row);
						if (scope != null) {
							var imp = GmlFile.current.codeEditor.imports[scope];
							if (imp != null) {
								var s = imp.longenEnum[name];
								if (s != null) name = s;
							}
						}
						//
						var en = GmlAPI.gmlEnums[name];
						if (en != null) {
							callback(null, en.fieldComp);
							return;
						}
					};
					default:
				}
			} while (false);
			proc(false);
			return;
		}
		//
		var tkf:Bool = tokenFilter.exists(JsTools.nca(tk, tk.type));
		if (!tkf && tokenFilterComment && tk.type.startsWith("comment")) tkf = true;
		proc(tkf != tokenFilterNot);
	}
	public function getDocTooltip(item:AceAutoCompleteItem):String {
		return item.doc;
	}
}
class AceWrapCompleterCustom extends AceWrapCompleter {
	public var func:AceWrapCompleterCustomFunc;
	public function new(
		items:AceAutoCompleteItems,
		tokenFilterDictOrArray:EitherType<Dictionary<Bool>, Array<AceTokenType>>, not:Bool,
		modeFilter:AceSession->Bool, fn:AceWrapCompleterCustomFunc
	) {
		func = fn;
		super(items, tokenFilterDictOrArray, not, modeFilter);
	}
	
	override public function getCompletions(editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb):Void {
		var ml = procMinLength();
		if (prefix.length < ml || !modeFilter(session)) {
			callback(null, AceWrapCompleter.noItems);
			return;
		}
		//
		var tk:AceToken = session.getTokenAtPos(pos);
		var tkf:Bool = tokenFilter.exists(tk.type);
		if (!tkf && tokenFilterComment && tk.type.startsWith("comment")) tkf = true;
		if (tkf != tokenFilterNot) {
			var r = func(this, editor, session, pos, prefix, callback);
			if (r != null) {
				callback(null, r ? items : AceWrapCompleter.noItems);
			}
		} else callback(null, AceWrapCompleter.noItems);
	}
}
typedef AceWrapCompleterCustomFunc = (completer:AceWrapCompleterCustom, editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb)->Bool;
abstract AceWrapCompleterMinLength(Int) from Int to Int {
	/// 2 normally, 1 in section match mode
	public static inline var Default = -4;
}
enum abstract AceWrapCompleterDotKind(Int) {
	var DKNone = 0;
	var DKGlobal = 1;
	var DKNamespace = 2;
	var DKEnum = 3;
	//var DKLocalType = 4;
	var DKSmart = 5;
}
enum abstract AceWrapCompletionColKind(Int) {
	var CKNone = 0;
	var CKNamespaces = 1;
	var CKEnums = 2;
}
