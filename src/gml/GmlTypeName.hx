package gml;
import ace.AceGmlTools;
import ace.extern.AceTokenType;
import gml.GmlFuncDoc;
import js.lib.RegExp;
import tools.Dictionary;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
abstract GmlTypeName(String) to String {
	public static inline var number:GmlTypeName = fromString("number");
	public static inline var bool:GmlTypeName = fromString("bool");
	public static inline var string:GmlTypeName = fromString("string");
	public static var kindMap:Dictionary<AceTokenType> = Dictionary.fromKeys([
		"number", "string", "bool", // primitives
		"array", "list", "map", "grid", "type",
		"Array", "List", "Map", "Grid", "Type",
	], "namespace");
	public static inline function array(elemType:GmlTypeName):GmlTypeName {
		return fromString("array<" + elemType + ">");
	}
	public static inline function type(name:GmlTypeName):GmlTypeName {
		return fromString("type<" + name + ">");
	}
	
	public static inline function fromString(s:String):GmlTypeName {
		return cast s;
	}
	
	public var isArray(get, never):Bool;
	private inline function get_isArray():Bool {
		return __isArray.test(this);
	}
	private static var __isArray:RegExp = new RegExp("^[Aa]rray<", "");
	
	public var isType(get, never):Bool;
	private inline function get_isType():Bool {
		return __isType.test(this);
	}
	private static var __isType:RegExp = new RegExp("^[Tt]ype<", "");
	
	public var isGrid(get, never):Bool;
	private inline function get_isGrid():Bool {
		return __isGrid.test(this);
	}
	private static var __isGrid:RegExp = new RegExp("^(?:ds_)?[Gg]rid<");
	
	public var isList(get, never):Bool;
	private inline function get_isList():Bool {
		return __isList.test(this);
	}
	private static var __isList:RegExp = new RegExp("^(?:ds_)?[Ll]ist<");
	
	public var isMap(get, never):Bool;
	private inline function get_isMap():Bool {
		return __isMap.test(this);
	}
	private static var __isMap:RegExp = new RegExp("^(?:ds_)?[Mm]ap<");
	
	public var isParam(get, never):Bool;
	private inline function get_isParam():Bool {
		return __isParam.test(this);
	}
	private static var __isParam:RegExp = new RegExp("^\\S+<");
	
	public function unwrapParam():GmlTypeName {
		var mt = __unwrapParam.exec(this);
		return JsTools.nca(mt, GmlTypeName.fromString(mt[1]));
	}
	private static var __unwrapParam:RegExp = new RegExp("^\\S+<\\s*(.+)\\s*>$");
	
	public function getSelfCallDoc(imp:GmlImports):GmlFuncDoc {
		return JsTools.nca(this, AceGmlTools.findSelfCallDoc(cast this, imp));
	}
}
