package gml.type;
import gml.GmlFuncDoc;
import haxe.ds.ReadOnlyArray;
import tools.Dictionary;
import tools.ReadOnlyDictionary;

/**
 * Represents a reference to a GML type.
 * By all means immutable and gets cached per input string.
 * @author YellowAfterlife
 */
@:using(gml.type.GmlTypeTools)
enum GmlType {
	
	TInst(name:String, params:ReadOnlyArray<GmlType>, kind:GmlTypeKind);
	
	/** any of */
	TEither(types:ReadOnlyArray<GmlType>);
	
	/** A {} literal */
	TAnon(inf:GmlTypeAnon);
	
	/**
	 * fn<T>(m:array<T>):T is processed as
	 * fn(m:array<TemplateItem<T, _0>>):TemplateItem<T, _0>
	 */
	TTemplate(name:String, ind:Int, constraint:GmlType);
	
	/** hint:type, e.g. in tuple<x:number, y:number> */
	THint(hint:String, type:GmlType);
	
	TSpecifiedMap(meta:GmlTypeMap);
	
	TEnumTuple(enumName:String);
}
class GmlTypeAnon {
	public var fields:Dictionary<GmlTypeAnonField> = new Dictionary();
	public function new() {}
}
class GmlTypeAnonField {
	public var type:GmlType;
	public var doc:GmlFuncDoc;
	public function new(t:GmlType, d:GmlFuncDoc) {
		this.type = t;
		this.doc = d;
	}
}

class GmlTypeMap {
	public var fieldMap(default, null):ReadOnlyDictionary<GmlTypeMapField>;
	public var fieldList(default, null):ReadOnlyArray<GmlTypeMapField>;
	public var defaultType(default, null):GmlType;
	public function new(
		fieldMap:ReadOnlyDictionary<GmlTypeMapField>,
		fieldList:ReadOnlyArray<GmlTypeMapField>,
		defaultType:GmlType
	) {
		this.fieldMap = fieldMap;
		this.fieldList = fieldList;
		this.defaultType = defaultType;
	}
}
class GmlTypeMapField {
	public var name(default, null):String;
	public var type(default, null):GmlType;
	public function new(name:String, type:GmlType) {
		this.name = name;
		this.type = type;
	}
}

@:build(gml.type.GmlTypeMacro.build())
enum abstract GmlTypeKind(Int) {
	// Core types:
	var KAny = 0x01;
	var KCustom = 0x02;
	var KNullable = 0x03; // T?
	var KType = 0x04; // type<T>
	var KVoid = 0x05;
	var KTemplateItem = 0x06; // TemplateItem<> -> TTemplate
	var KTemplateSelf = 0x07; // TemplateSelf<> for filling out self-params
	var KGlobal = 0x08; // type of `global`
	var KFunction = 0x09; // (a:int, b:string)->any is function<int, string, any>
	var KRest = 0x0A; // `...v:T` in functions
	
	// value types
	var KUndefined = 0x10;
	var KNumber = 0x11;
	var KBool = 0x12;
	var KString = 0x13;
	
	// ref types
	var KArray = 0x20;
	var KList = 0x21;
	var KMap = 0x22;
	var KGrid = 0x23;
	
	var KCustomKeyArray = 0x28;
	var KTuple = 0x29;
	
	// Constraints:
	var KObject = 0x30; // any object type casts to this
	var KStruct = 0x31; // non-object namespaces cast to this
	var KAsset = 0x32; // any asset types and objects cast to this
	
	// Special:
	var KMethodSelf = 0x40; // used exclusively by linter to redirect `self` in second arg
	var KAnyFieldsOf = 0x41; // 
	
	private static function init() { } // autogen via @:build
	@:keep private static var __init = init();
}