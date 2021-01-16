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
	 * fn<T>(m:array<T>):T is processed as fn(m:array<TN<T0>>):TN<T0>
	 */
	TTemplate(ind:Int);
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
}