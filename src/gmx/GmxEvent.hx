package gmx;
import ace.AceWrap;
import electron.FileSystem;
import gml.GmlEvent;
import haxe.ds.StringMap;
import haxe.io.Path;
import tools.Dictionary;

/**
 * 
 * @author YellowAfterlife
 */
class GmxEvent {
	public static inline function toString(type:Int, numb:Int, name:String) {
		return GmlEvent.toString(type, numb, name);
	}
	public static inline function fromString(name:String):GmlEventData {
		return GmlEvent.fromString(name);
	}
}
