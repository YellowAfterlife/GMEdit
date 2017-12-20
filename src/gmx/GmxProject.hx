package gmx;
import gml.GmlReader;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxProject {
	public static function getMacroCode(gmx:SfGmx, isConfig:Bool):String {
		var out = "// note: only #macro definitions here are saved";
		if (isConfig) gmx = gmx.find("ConfigConstants");
		if (gmx != null) for (mcrParent in gmx.findAll("constants"))
		for (mcrNode in mcrParent.findAll("constant")) {
			var name = mcrNode.get("name");
			var expr = mcrNode.text;
			out += '\n#macro $name $expr';
		}
		return out;
	}
	public static function setMacroCode(gmx:SfGmx, gmlCode:String, isConfig:Bool):Bool {
		var q = new GmlReader(gmlCode);
		//
		var mcrOuter = isConfig ? gmx.find("ConfigConstants") : gmx;
		var mcrParent = mcrOuter.find("constants");
		if (mcrParent == null) {
			mcrParent = new SfGmx("constants");
			mcrOuter.addChild(mcrParent);
		} else mcrParent.clearChildren();
		var found = 0;
		//
		while (q.loop) {
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skip();
						q.skipLine();
					};
					case "*".code: {
						q.skip();
						q.skipComment();
					};
					default:
				};
				case '"'.code, "'".code: {
					q.skipString1(c);
				};
				case "#".code: {
					if (q.substr(q.pos, 5) != "macro") continue;
					//
					q.skip(5);
					// skip spaces:
					while (q.loop) {
						c = q.peek();
						if (c.isSpace0()) {
							q.skip();
						} else break;
					}
					// read name:
					var start = q.pos;
					while (q.loop) {
						c = q.peek();
						if (c.isIdent1()) {
							q.skip();
						} else break;
					}
					var name = q.substring(start, q.pos);
					// skip spaces after:
					while (q.loop) {
						c = q.peek();
						if (c.isSpace0()) {
							q.skip();
						} else break;
					}
					// read expr:
					start = q.pos;
					while (q.loop) switch (q.peek()) {
						case "\r".code, "\n".code: {
							break;
						};
						default: q.skip();
					}
					var expr = q.substring(start, q.pos);
					//
					var mcrNode = new SfGmx("constant", expr);
					mcrNode.set("name", name);
					mcrParent.addChild(mcrNode);
					found += 1;
				};
				default:
			} // switch (q.read)
		} // while (loop)
		mcrParent.set("number", "" + found);
		return true;
	}
}
