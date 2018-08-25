package gml;

/**
 * ...
 * @author YellowAfterlife
 */
@:build(tools.AutoEnum.build("int"))
@:enum abstract GmlVersion(Int) to Int {
	/** not set yet */
	var none = 0;
	
	/** GMS1 */
	var v1 = 1;
	
	/** GMS2 */
	var v2 = 2;
	
	/** GMLive variant (has template strings and a few extra keywords) */
	var live = -1;
	
	public inline function hasStringEscapeCharacters() {
		return this == v2;
	}
	public inline function hasLiteralStrings() {
		return this == v2;
	}
	public inline function hasSingleQuoteStrings() {
		return this != v2;
	}
	
	/** Whether GMLive specific string interpolation is supported */
	public inline function hasTemplateStrings() {
		#if lwedit
		return true;
		#else
		return this == live;
		#end
	}
	
	/** Whether the ternary operator is supported */
	public inline function hasTernaryOperator() {
		return this != v1;
	}
	
	/** Whether GMS2 style `/// @meta` docs are used */
	public inline function hasJSDoc() {
		return this == v2;
	}
	
	/** Whether it's allowed to do `#define script(arg1, arg2)` */
	public inline function hasScriptArgs() {
		#if lwedit
		return true;
		#else
		return this == live;
		#end
	}
	
	/** Whether a #define/#event/etc. resets line counter */
	public inline function resetOnDefine() {
		#if lwedit
		return false;
		#else
		return this != live;
		#end
	}
	
	public function getName() {
		return null;
	}
	
	public static function verify(gml:String, v:Int):Bool {
		var q = new tools.StringReader(gml);
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
	public static function detect(gml:String):GmlVersion {
		gml += "\n";
		if (verify(gml, 2)) return v2;
		if (verify(gml, 1)) return v1;
		return none;
	}
}
