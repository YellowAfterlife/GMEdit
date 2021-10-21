package gml;
import ace.AceWrap;
import ace.extern.*;
import gml.type.GmlType;
import tools.Aliases;
import tools.Dictionary;
import gml.GmlAPI;

/**
 * Represents a GML enum declaration, along with constructs inside.
 * @author YellowAfterlife
 */
class GmlEnum extends GmlStruct {
	//
	public var typeComp:AceAutoCompleteItem;
	public var names:Array<String> = [];
	public var items:Dictionary<Bool> = new Dictionary();
	public var compList:AceAutoCompleteItems = [];
	public var compMap:Dictionary<AceAutoCompleteItem> = new Dictionary();
	public var fieldComp:AceAutoCompleteItems = [];
	public var fieldLookup:Dictionary<GmlLookup> = new Dictionary();
	
	/** "C" for `enum Q {A,B,C}` */
	public var lastItem:GmlName = null;
	
	/** If @is was used, contains per-index types */
	public var tupleTypes:Array<GmlType> = null;
	//
	public function new(name:String, orig:String) {
		super(name, orig);
		typeComp = new AceAutoCompleteItem(name, "enum");
	}
	//
}
