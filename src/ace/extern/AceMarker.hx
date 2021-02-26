package ace.extern;
import ace.extern.AceSession;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AceMarker {
	// it's actually just an int id
}
extern class AceMarkerConfig {
	//
}
extern class AceMarkerBuf {
	// technically unused
}
extern class AceMarkerLayer {
	function drawFullLineMarker(html:AceMarkerBuf, range:AceRange, clazz:String, config:AceMarkerConfig, style:String):Void;
}
interface IAceMarker {
	var id:AceMarker;
	var inFront:Bool;
}
interface IAceDynamicMarker extends IAceMarker {
	function update(html:AceMarkerBuf, markerLayer:AceMarkerLayer, session:AceSession, config:AceMarkerConfig):Void;
}