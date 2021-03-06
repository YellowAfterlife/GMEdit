package ace.gml;
import ace.extern.AceMarker;
import ace.extern.AceRange;
import ace.extern.AceSession;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceGmlWarningMarker implements IAceDynamicMarker {
	var __row:Int;
	var __line:String;
	var __range:AceRange;
	var __clazz:String;
	public var id:AceMarker;
	public var inFront:Bool;
	
	public function new(session:AceSession, row:Int, clazz:String) {
		__row = row;
		__clazz = clazz;
		__line = session.getLine(row);
		__range = new AceRange(0, row, __line.length, row);
	}
	public function addTo(session:AceSession):AceMarker {
		session.addDynamicMarker(this);
		var dynSession:Dynamic = cast session;
		if (dynSession.__AceGmlWarningMarker == null) {
			dynSession.__AceGmlWarningMarker = true;
			dynSession.on("change", function(delta:AceRange) {
				var startRow = delta.start.row;
				var endRow = delta.end.row;
				var rowCount = endRow - startRow;
				var isRemove = (cast delta).action == "remove";
				if (isRemove) rowCount = -rowCount;
				var toRemove = [];
				for (id in session.gmlErrorMarkers) {
					var m = session.__backMarkers[cast id];
					if (!(m is AceGmlWarningMarker)) continue;
					var mk:AceGmlWarningMarker = cast m;
					var mkRow = mk.__row;
					if (mkRow < startRow) continue;
					if (mkRow < endRow
						//|| (mkRow == endRow && rowCount == 0 && !isRemove)
					) {
						toRemove.push(id);
						//Console.log("Removing", mk, delta);
					} else {
						mk.__row += rowCount;
						mk.__range.start.row += rowCount;
						mk.__range.end.row += rowCount;
						//Console.log(mkRow, rowCount, delta);
					}
				}
				for (id in toRemove) session.removeMarker(id);
			});
		}
		return id;
	}
	
	/**
	 * implements AceDynamicMarker
	 */
	public function update(html:AceMarkerBuf, markerLayer:AceMarkerLayer, session:AceSession, config:AceMarkerConfig):Void {
		var range = __range.clipRows(config.firstRow, config.lastRow);
		if (range.isEmpty()) return;
		range = range.toScreenRange(session);
		markerLayer.drawFullLineMarker(html, range, __clazz, config, "position: absolute");
	}
}
