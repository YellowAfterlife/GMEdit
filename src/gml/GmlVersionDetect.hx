package gml;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlVersionDetect {
	public static function verify(gml:String, v:Int):Bool {
		var q = new parsers.GmlReader(gml);
		while (q.loop) {
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skip();
						while (q.loop) {
							switch (q.peek()) {
								case "\r".code, "\n".code: { }; // ->
								default: q.skip(); continue;
							}; break;
						}
					};
					case "*".code: {
						q.skip();
						while (q.loop) {
							if (q.peek() == "*".code) {
								q.skip();
								if (q.peek() == "/".code) {
									q.skip();
									break;
								}
							} else q.skip();
						}
					};
					default:
				};
				case "@".code: switch (q.peek()) {
					case '"'.code: {
						if (v < 2) return false;
						q.skip();
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
						}
						if (!q.loop) return false;
					};
					case "'".code: {
						if (v < 2) return false;
						q.skip();
						while (q.loop) {
							c = q.read();
							if (c == "'".code) break;
						}
						if (!q.loop) return false;
					};
					default:
				}; // case "@".code
				case "'".code: {
					if (v >= 2) {
						return false;
					} else {
						while (q.loop) {
							c = q.read();
							if (c == "'".code) break;
						}
						if (!q.loop) return false;
					}
				};
				case '"'.code: {
					if (v >= 2) {
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
							if (c == "\\".code) switch (c) {
								case "u".code: q.pos += 5;
								case "x".code: q.pos += 3;
								default: q.pos += 1;
							}
						}
						if (!q.loop) return false;
					} else {
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
						}
						if (!q.loop) return false;
					}
				};
				default:
			} // switch (c)
		}
		return true;
	}
	//
	public static function run(gml:String):GmlVersion {
		gml += "\n";
		if (verify(gml, 2)) return GmlVersion.v2;
		if (verify(gml, 1)) return GmlVersion.v1;
		return GmlVersion.none;
	}
}
