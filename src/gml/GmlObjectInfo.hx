package gml;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlObjectInfo {
	public var spriteName:String;
	public var parents:Array<String> = [];
	public var children:Array<String> = [];
	public var eventList:Array<String> = [];
	/** event name -> [parent name, child name] */
	public var eventMap:Dictionary<Array<String>>;
	public function new() {
		
	}
	
}
