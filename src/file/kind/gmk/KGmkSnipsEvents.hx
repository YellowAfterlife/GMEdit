package file.kind.gmk;

import file.kind.gml.KGmlEvents;
import gmk.GmkEvent;
import gml.GmlLocals;
import haxe.io.Path;
import parsers.GmlMultifile;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmkSnipsEvents extends KGmlEvents {
	public static var inst:KGmkSnipsEvents = new KGmkSnipsEvents();
	
	override public function index(path:String, content:String, main:String, sync:Bool):Bool {
		var objectName = path.ptName2();
		var out = new GmlSeekData(this);
		var pairs = GmlMultifile.split(content, "properties", "event");
		out.addObjectHint(objectName, null);
		for (pair in pairs) {
			var name = pair.name;
			var locals = new GmlLocals(name);
			out.locals.set(name, locals);
			GmlSeeker.runSyncImpl(path, pair.code, null, out, locals, this);
		}
		GmlSeeker.finish(path, out);
		return true;
	}
}