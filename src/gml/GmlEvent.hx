package gml;
import ace.AceWrap;
import electron.FileSystem;
import haxe.ds.StringMap;
import haxe.io.Path;
import tools.Dictionary;

/**
 * todo: keyboard event conversion
 * @author YellowAfterlife
 */
class GmlEvent {
	public static inline var typeCollision:Int = 4;
	static var t2s:Array<String> = [];
	static var t2sc:Array<String> = [];
	static var s2t:Dictionary<Int> = new Dictionary();
	static var i2s:Array<Array<String>> = [];
	static var s2i:Dictionary<GmlEventData> = new Dictionary();
	/** */
	public static inline function getTypeNameCap(type:Int):String {
		return t2sc[type];
	}
	public static var comp:AceAutoCompleteItems = [];
	public static inline function exists(name:String):Bool {
		return s2i.exists(name);
	}
	//
	static function link(type:Int, numb:Int, name:String) {
		var arr = i2s[type];
		if (arr == null) {
			arr = [];
			i2s[type] = arr;
		}
		arr[numb] = name;
		s2i.set(name, { type: type, numb: numb });
	}
	static function linkType(type:Int, name:String) {
		t2s[type] = name;
		t2sc[type] = tools.NativeString.capitalize(name);
		s2t.set(name, type);
	}
	//
	public static function toString(type:Int, numb:Int, name:String) {
		if (type == typeCollision) {
			return "collision:" + name;
		}
		var arr = i2s[type];
		if (arr != null) {
			var out = arr[numb];
			if (out != null) return out;
		}
		var tName = t2s[type];
		if (tName != null) return tName + ":" + numb;
		return "event" + type + ":" + numb;
	}
	public static function fromString(name:String):GmlEventData {
		var out = s2i.get(name);
		if (out != null) return out;
		var i = name.indexOf(":");
		if (i < 0) return null;
		var type = s2t[name.substring(0, i)];
		if (type == null) return null;
		if (type == typeCollision) {
			return { type: type, numb: null, name: name.substring(i + 1) };
		}
		var numb = Std.parseInt(name.substring(i + 1));
		if (numb == null) return null;
		return { type: type, numb: numb };
	}
	//
	public static var parseError:String;
	/**
	 * Splits GML code on 
	 */
	public static function parse(gmlCode:String, version:GmlVersion):GmlEventList {
		var eventData:GmlEventList = [];
		var errors = "";
		var q = new GmlReader(gmlCode);
		var evStart = 0;
		var evCode:Array<String> = [];
		var evName = null;
		//
		var flushHeader:String = null;
		function flush(till:Int, ?sctName:String):Void {
			var flushCode = tools.NativeString.trimRight(q.substring(evStart, till));
			if (evName == null) {
				if (flushCode != "") {
					errors += "There's code prior to first event definition.\n";
					//trace(flushCode);
				}
			} else {
				var flushData = GmlEvent.fromString(evName);
				if (flushData != null) {
					if (flushHeader != null) {
						flushCode = '///$flushHeader\n' + flushCode;
					}
					evCode.push(flushCode + "\r\n");
					if (sctName == null) {
						eventData.push({ data: flushData, code: evCode });
						evCode = [];
						flushHeader = null;
					} else flushHeader = sctName;
				} else errors += '`$evName` is not a known event type.\n';
			}
		}
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
					if (q.pos > 1) switch (q.get(q.pos - 2)) {
						case "\r".code, "\n".code: { };
						default: continue;
					}
					if (q.substr(q.pos, 5) == "event") {
						//
						flush(q.pos - 1);
						q.skip(5);
						// skip spaces:
						q.skipSpaces0();
						// read name:
						var nameStart = q.pos;
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1() || c == ":".code) {
								q.skip();
							} else break;
						}
						evName = q.substring(nameStart, q.pos);
						// skip spaces after:
						q.skipSpaces0();
						// skip line:
						if (q.loop) switch (q.peek()) {
							case "\r".code: {
								q.skip();
								if (q.loop && q.peek() == "\n".code) q.skip();
							};
							case "\n".code: q.skip();
						}
						evStart = q.pos;
					} else if (q.substr(q.pos, 7) == "section" && version == GmlVersion.v1) {
						q.skip(7);
						//
						var nameStart = q.pos;
						var nameEnd = -1;
						while (q.loop) switch (q.peek()) {
							case "\r".code: {
								nameEnd = q.pos;
								q.skip();
								if (q.loop && q.peek() == "\n".code) q.skip();
								break;
							};
							case "\n".code: {
								nameEnd = q.pos;
								q.skip();
								break;
							}
							default: q.skip();
						}
						if (nameEnd < 0) nameEnd = q.length;
						var name = q.substring(nameStart, nameEnd);
						flush(nameStart - 8, name);
						//
						evStart = q.pos;
					}
				};
				default:
			} // switch (q.read)
		}
		flush(q.pos);
		if (errors != "") {
			parseError = errors;
			return null;
		} else return eventData;
	}
	//
	public static function init() {
		// define event names (used for GMS2 paths and when no name is available):
		for (i in 0 ... 16) linkType(i, "event" + i);
		linkType(0, "create");
		linkType(1, "destroy");
		linkType(2, "alarm");
		linkType(3, "step");
		linkType(4, "collision");
		linkType(5, "keyboard");
		linkType(6, "mouse");
		linkType(7, "other");
		linkType(8, "draw");
		linkType(9, "keypress");
		linkType(10, "keyrelease");
		linkType(12, "cleanup"); t2sc[12] = "CleanUp";
		linkType(13, "gesture");
		// set up auto-completion for events that have ":id" suffix:
		comp.push(new AceAutoCompleteItem("collision", "event"));
		comp.push(new AceAutoCompleteItem("keypress", "event"));
		comp.push(new AceAutoCompleteItem("keyrelease", "event"));
		comp.push(new AceAutoCompleteItem("keyboard", "event"));
		// read event names from the file:
		var data = FileSystem.readFileSync(Main.relPath("api/events.gml"), "utf8");
		tools.ERegTools.each(~/^(\d+):(\d+)[ \t]+(\w+)/gm, data, function(rx:EReg) {
			var name = rx.matched(3);
			comp.push(new AceAutoCompleteItem(name, "event"));
			link(Std.parseInt(rx.matched(1)), Std.parseInt(rx.matched(2)), name);
		});
	}
}
typedef GmlEventData = { type:Int, numb:Int, ?name:String, ?obj:yy.YyGUID };
typedef GmlEventList = Array<{ data:GmlEventData, code:Array<String> }>;
