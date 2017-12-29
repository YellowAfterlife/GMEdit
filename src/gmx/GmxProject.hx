package gmx;
import gml.GmlReader;
import tools.StringBuilder;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxProject {
	public static function getMacroCode(gmx:SfGmx, notes:GmlReader, isConfig:Bool):String {
		var out = "";
		if (isConfig) gmx = gmx.find("ConfigConstants");
		if (gmx != null) for (mcrParent in gmx.findAll("constants"))
		for (mcrNode in mcrParent.findAll("constant")) {
			var name = mcrNode.get("name");
			var expr = mcrNode.text;
			out += '#macro $name $expr\n';
		}
		if (notes != null) {
			var q = notes;
			var flush0 = 0;
			while (q.loop) {
				var flush1 = q.pos;
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
						q.skip(5);
						// skip spaces:
						q.skipSpaces0();
						// read name:
						var start = q.pos;
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1()) {
								q.skip();
							} else break;
						}
						var name = q.substring(start, q.pos);
						//
						q.skipLine();
						q.skipLineEnd();
						//
						if (flush1 > flush0) {
							var flush = q.substring(flush0, flush1);
							var at = out.indexOf("#macro " + name);
							if (at >= 0) {
								out = out.substring(0, at) + flush + out.substring(at);
							} else out += flush;
						}
						flush0 = q.pos;
					}
				}
			} // while (q.loop)
			if (q.pos > flush0) out += q.substring(flush0, q.pos);
		}
		return out;
	}
	public static function setMacroCode(
		gmx:SfGmx, gmlCode:String, notes:StringBuilder, isConfig:Bool
	):Bool {
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
		var flush0 = 0;
		while (q.loop) {
			var flush1 = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skipLine();
						q.skipLineEnd();
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
					q.skipSpaces0();
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
					q.skipSpaces0();
					// read expr:
					start = q.pos;
					q.skipLine();
					var expr = q.substring(start, q.pos);
					//
					q.skipLineEnd();
					//
					var mcrNode = new SfGmx("constant", expr);
					mcrNode.set("name", name);
					mcrParent.addChild(mcrNode);
					//
					if (flush1 > flush0) {
						notes.addString(q.substring(flush0, flush1));
						notes.addFormat("#macro %s\n", name);
					}
					flush0 = q.pos;
					//
					found += 1;
				};
				default:
			} // switch (q.read)
		} // while (loop)
		if (q.pos > flush0) notes.addString(q.substring(flush0, q.pos));
		mcrParent.set("number", "" + found);
		return true;
	}
}
