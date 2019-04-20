package ace;
import ace.AceWrap;
import ace.extern.*;
import ace.extern.AceCommandManager;
import file.kind.misc.KGLSL;
import file.kind.misc.KHLSL;
import gml.GmlAPI;
import gml.GmlImports;
import gml.GmlScopes;
import gml.file.GmlFile;
import parsers.GmlKeycode;
import parsers.GmlEvent;
import shaders.ShaderAPI;
import tools.Dictionary;
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
	public var colKind:AceWrapCompletionColKind = CKNone;
	
	public function new(
		items:AceAutoCompleteItems, filters:Array<String>, not:Bool,
		modeFilter:AceSession->Bool
	) {
		items.autoSort();
		this.items = items;
		this.tokenFilter = Dictionary.fromKeys(filters, true);
		this.tokenFilterComment = tokenFilter["comment"];
		this.tokenFilterNot = not;
		this.modeFilter = modeFilter;
	}
	
	public static function checkColon(iter:AceTokenIterator) {
		// `var [some]:type`:
		var token = iter.stepBackward();
		if (token != null && token.type == "text") token = iter.stepBackward();
		if (token == null) return false;
		switch (token.type) {
			case "local", "sublocal", "localfield": {};
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
	// interface AceAutoCompleter
	public function getCompletions(
		editor:AceEditor, session:AceSession, pos:AcePos, prefix:String, callback:AceAutoCompleteCb
	):Void {
		inline function proc(show:Bool) {
			callback(null, show ? items : noItems);
		}
		var ml = minLength;
		switch (ml) {
			case AceWrapCompleterMinLength.Default: {
				ml = ui.Preferences.current.compMatchMode == SectionStart ? 1 : 2;
			};
		}
		if (prefix.length < ml || !modeFilter(session)) {
			proc(false);
			return;
		}
		if (editor.completer != null) {
			editor.completer.exactMatch = ui.Preferences.current.compExactMatch;
		}
		var tk:AceToken = session.getTokenAtPos(pos);
		if (colKind != CKNone) {
			if (tk.type == "punctuation.operator" && tk.value.contains(":")) do { // once
				var iter = new AceTokenIterator(session, pos.row, pos.column);
				if (checkColon(iter)) switch (colKind) {
					case CKNamespaces: {
						var scope = session.gmlScopes.get(pos.row);
						if (scope == null) break;
						var imp = GmlFile.current.codeEditor.imports[scope];
						if (imp == null) break;
						callback(null, imp.namespaceComp);
					};
					case CKEnums: callback(null, GmlAPI.gmlEnumTypeComp);
					default: continue;
				}
				return;
			} while (false); // once
			proc(false);
			return;
		}
		else if (dotKind != DKNone && tk.type == "punctuation.operator" && tk.value.contains(".")) {
			var iter = new AceTokenIterator(session, pos.row, pos.column);
			tk = iter.stepBackward();
			switch (dotKind) {
				case DKNamespace: {
					if (tk.type == "namespace") {
						var scope = session.gmlScopes.get(pos.row);
						if (scope != null) {
							var imp = GmlFile.current.codeEditor.imports[scope];
							if (imp != null) {
								var ns = imp.namespaces[tk.value];
								if (ns != null) {
									callback(null, ns.comp);
									return;
								}
							}
						}
					}
					proc(false);
				};
				case DKLocalType: {
					if (tk.type == "local") {
						var scope = session.gmlScopes.get(pos.row);
						if (scope != null) {
							var imp = GmlFile.current.codeEditor.imports[scope];
							if (imp != null) {
								var t = imp.localTypes[tk.value];
								if (t != null) {
									var ns = imp.namespaces[t];
									if (ns != null) {
										callback(null, ns.comp);
										return;
									} else {
										var en = GmlAPI.gmlEnums[t];
										if (en != null) {
											callback(null, en.fieldComp);
											return;
										}
									}
								}
							}
						}
					}
					proc(false);
				};
				case DKGlobal: {
					proc(tk.value == "global");
				};
				case DKEnum: {
					if (tk.type == "enum") {
						var name = tk.value;
						//
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
					}
					proc(false);
				};
				default:
			}
			return;
		}
		var tkf:Bool = tokenFilter.exists(tk.type);
		if (!tkf && tokenFilterComment && tk.type.startsWith("comment")) tkf = true;
		proc(tkf != tokenFilterNot);
	}
	public function getDocTooltip(item:AceAutoCompleteItem):String {
		return item.doc;
	}
}
abstract AceWrapCompleterMinLength(Int) from Int to Int {
	/// 2 normally, 1 in section match mode
	public static inline var Default = -4;
}
enum abstract AceWrapCompleterDotKind(Int) {
	var DKNone = 0;
	var DKGlobal = 1;
	var DKNamespace = 2;
	var DKEnum = 3;
	var DKLocalType = 4;
}
enum abstract AceWrapCompletionColKind(Int) {
	var CKNone = 0;
	var CKNamespaces = 1;
	var CKEnums = 2;
}
