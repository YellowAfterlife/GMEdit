package gml.type;
import gml.GmlFuncDoc;
import haxe.ds.ReadOnlyArray;
import tools.Dictionary;

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

enum abstract GmlTypeKind(Int) {
	var KAny = 0x01;
	var KCustom = 0x02;
	var KNullable = 0x03; // T?
	var KType = 0x04; // type<T>
	var KVoid = 0x05;
	var KTemplateItem = 0x06; // TemplateItem<> -> TTemplate
	var KTemplateSelf = 0x07; // TemplateSelf<> for filling out self-params
	
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
	
	// Constraints:
	var KObject = 0x30; // any object type casts to this
	var KStruct = 0x31; // non-object namespaces cast to this
	var KAsset = 0x32; // any asset types and objects cast to this
}