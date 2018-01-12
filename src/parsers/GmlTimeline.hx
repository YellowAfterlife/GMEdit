package parsers;
import parsers.GmlReader;
import tools.NativeString;
import gml.GmlVersion;

/**
 * Handles conversion of combined code (with #moment headers) back into moment-code pairs.
 * @author YellowAfterlife
 */
class GmlTimeline {
	public static var parseError:String;
	public static function parse(gmlCode:String, version:GmlVersion):Array<GmlTimelineData> {
		var out:Array<GmlTimelineData> = [];
		var errors = "";
		var q = new GmlReader(gmlCode);
		//
		var mmStart:Int = 0;
		var mmTime:Null<Int> = null;
		var mmCode:Array<String> = [];
		var sctName:String = null;
		function flush(till:Int, ?cont:Bool) {
			var mmNext = NativeString.trimRight(q.substring(mmStart, till));
			if (mmTime == null) {
				if (mmNext != "") errors += "There's code prior to first moment definition.\n";
			} else {
				if (sctName != null && sctName != "") {
					var pfx:String = (version == GmlVersion.v2) ? "/// @desc" : "///";
					pfx += sctName + "\r\n";
					mmNext = pfx + mmNext;
					sctName = null;
				}
				mmCode.push(mmNext);
				if (!cont) {
					out.push({ moment: mmTime, code: mmCode });
					mmCode = [];
				}
			}
		}
		//
		while (q.loop) {
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "#".code: if (q.pos == 1 || q.get(q.pos - 2) == "\n".code) {
					if (q.substr(q.pos, 6) == "moment") {
						flush(q.pos - 1);
						q.skip(6);
						//
						q.skipSpaces0();
						//
						var timeStart = q.pos;
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1()) q.skip(); else break;
						}
						var timeString = q.substring(timeStart, q.pos);
						mmTime = Std.parseInt(timeString);
						if (mmTime == null) errors += timeString + " is not a valid moment number.";
						//
						timeStart = q.pos;
						q.skipLine();
						sctName = q.substring(timeStart, q.pos);
						q.skipLineEnd();
						//
						mmStart = q.pos;
					} else if (q.substr(q.pos, 7) == "section" && version == GmlVersion.v1) {
						q.skip(7);
						var nameStart = q.pos;
						q.skipLine();
						var nameEnd = q.pos;
						q.skipLineEnd();
						flush(nameStart - 8, true);
						sctName = q.substring(nameStart, nameEnd);
						//
						mmStart = q.pos;
					}
				};
				default:
			} // switch (c)
		} // while (q.loop)
		flush(q.pos);
		if (errors != "") {
			parseError = errors;
			return null;
		} else return out;
	}
}
typedef GmlTimelineData = { moment:Int, code:Array<String> };
