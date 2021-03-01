package gml;

/**
 * Not a struct-struct, but rather a parent for other definitions.
 * @author YellowAfterlife
 */
class GmlStruct {
	
	/** Name of the thing */
	public var name:String;
	
	/** Where the thing was initially defined */
	public var origin:String;
	
	public function new(name:String, orig:String) {
		this.name = name;
		origin = orig;
	}
	
}
