package parsers;
import ace.AceWrap;
import ace.extern.*;
import electron.FileSystem;
import gml.GmlVersion;
import haxe.ds.StringMap;
import haxe.io.Path;
import parsers.GmlReader;
import tools.Dictionary;
using tools.NativeString;

/**
 * Handles general-purpose event name encoding/decoding,
 * as well as splitting combined code back into individual events.
 * @author YellowAfterlife
 */
class GmlEvent {
	public static inline var typeCollision:Int = 4;
	/** GM8 only! **/
	public static inline var typeTrigger:Int = 11;
	/** GMEdit-specific, not a real event */
	public static inline var typeMagic:Int = -1;
	public static inline var kindMagicProperties:Int = 1;
	public static inline function isKeyType(t:Int) {
		return t == 5 || t == 9 || t == 10;
	}
	static var t2s:Array<String> = [];
	static var t2sc:Array<String> = [];
	static var s2t:Dictionary<Int> = new Dictionary();
	static var sc2t:Dictionary<Int> = new Dictionary();
	static var i2s:Array<Array<String>> = [];
	static var s2i:Dictionary<GmlEventData> = new Dictionary();
	/** Returns index for a CapitalizedName **/
	public static inline function getCapTypeIndex(name:String):Null<Int> {
		return sc2t[name];
	}
	/** Returns rawname of given event type */
	public static inline function getTypeName(type:Int):String {
		return t2s[type];
	}
	/** Returns CapitalizedName of given event type */
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
		var nlq = name.toLowerCase();
		t2s[type] = nlq;
		t2sc[type] = name;
		s2t.set(nlq, type);
		sc2t.set(name, type);
	}
	//
	public static function toString(type:Int, numb:Int, name:String) {
		if (type == typeCollision) return "collision:" + name;
		if (type == typeTrigger) return "trigger:" + name;
		//
		var arr = i2s[type];
		if (arr != null) {
			var out = arr[numb];
			if (out != null) return out;
		}
		var tName = t2s[type];
		if (isKeyType(type)) return tName + ":" + GmlKeycode.toName(numb);
		if (tName != null) return tName + ":" + numb;
		return "event" + type + ":" + numb;
	}
	public static function fromString(name:String):GmlEventData {
		var out = s2i.get(name);
		if (out != null) return out;
		var i = name.indexOf(":");
		if (i < 0) return null;
		var type = s2t[name.substring(0, i)];
		var name = name.substring(i + 1);
		if (type == null) return null;
		switch (type) {
			case typeCollision, typeTrigger:
				return { type: type, numb: null, name: name };
		}
		if (isKeyType(type)) {
			var key = GmlKeycode.fromName(name);
			if (key == null) return null;
			return { type: type, numb: key };
		}
		var numb = Std.parseInt(name);
		if (numb == null) return null;
		return { type: type, numb: numb };
	}
	//
	public static var parseError:String;
	/**
	 * Splits GML code on #event
	 */
	public static function parse(gmlCode:String, version:GmlVersion):GmlEventList {
		var eventData:GmlEventList = [];
		var eventMap = new Dictionary<Bool>();
		var errors = "";
		var q = new GmlReader(gmlCode);
		var evStart = 0;
		var evCode:Array<String> = [];
		var evName = null;
		var sctName = null;
		var isAutoSection = true;
		/**
		   @param	till	Final character to grab data till
		   @param	cont	Whether this is a section/action, continuing same event
		   @param	eof 	Whether called by reaching end of the file
		**/
		function flush(till:Int, cont:Bool, ?eof:Bool):Void {
			var flushCode = q.substring(evStart, till);
			/*
			Expected structure:
			<snip>#event properties
			parent_index = -1;
			
			#event create
			// code with no trailing newlines
			#section
			// code with no trailing newlines
			
			#event draw
			// code with no trailing newlines</snip>
			So events are separated with 2 newlines (one empty),
			actions/sections are separated by 1 (tight fit if there are no trailing ones),
			and no extra newlines are kept at EOF.
			*/
			flushCode = flushCode.trimTrailRn(eof ? 0 : (cont ? 1 : 2));
			if (evName == null) {
				if (flushCode != "") {
					errors += "There's code prior to first event definition.\n";
					//trace(flushCode);
				}
			} else {
				if (sctName != null && sctName != "") {
					flushCode = '///' + sctName + '\r\n' + flushCode;
					sctName = null;
				}
				var flushData = GmlEvent.fromString(evName);
				if (flushData != null) {
					//
					if (!isAutoSection
						|| !cont && evCode.length == 0
						|| flushCode.trimBoth() != ""
					) {
						evCode.push(flushCode);
					}
					//
					if (!cont) {
						if (eventMap.exists(evName)) {
							errors += 'Duplicate event declaration found for `$evName`.\n';
						} else {
							eventData.push({ data: flushData, code: evCode });
							eventMap.set(evName, true);
						}
						evCode = [];
					}
				} else errors += '`$evName` is not a known event type.\n';
			}
		}
		//
		var hasEventSections = version.config.hasEventSections;
		var hasEventActions = version.config.hasEventActions;
		while (q.loop) {
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): q.skipDqTplString(version);
				case "#".code: { // #meta
					// line start only!
					if (q.pos > 1) switch (q.get(q.pos - 2)) {
						case "\r".code, "\n".code: { };
						default: continue;
					}
					//
					var hashPos = q.pos - 1;
					if (q.skipIfIdentEquals("event")) {
						flush(hashPos, false);
						// skip spaces:
						q.skipSpaces0();
						// read name:
						var nameStart = q.pos;
						q.skipEventName();
						evName = q.substring(nameStart, q.pos);
						// read label:
						nameStart = q.pos;
						q.skipSpaces0();
						q.skipLine();
						sctName = q.substring(nameStart, q.pos);
						if (sctName == "") {
							sctName = null;
						} else if (version.config.hasJSDoc) {
							if (sctName.charCodeAt(0) == "|".code) {
								sctName = ' @desc ' + sctName.substring(1);
							} else {
								sctName = ' @description' + sctName;
							}
						} else if (sctName.charCodeAt(0) == "|".code) {
							// `#event name|text` -> `///text`
							sctName = sctName.substring(1);
						}
						//
						q.skipLineEnd();
						//
						evStart = q.pos;
						isAutoSection = true;
						continue;
					} // event
					if (hasEventSections && q.skipIfIdentEquals("section")) {
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
						flush(hashPos, true);
						sctName = q.substring(nameStart, nameEnd);
						if (sctName.charCodeAt(0) == "|".code) {
							sctName = sctName.substring(1);
						}
						//
						evStart = q.pos;
						isAutoSection = false;
						continue;
					}
					if (hasEventSections && q.skipIfIdentEquals("with")) {
						flush(hashPos, true);
						q.skipLine();
						q.skipLineEnd();
						evStart = hashPos;
						isAutoSection = false;
						continue;
					}
					if (hasEventActions && q.skipIfIdentEquals("action")) {
						// we flush twice because action lines are their own blocks
						flush(hashPos, true);
						evStart = hashPos;
						q.skipLine();
						q.skipLineEnd();
						flush(q.pos, true);
						evStart = q.pos;
						isAutoSection = true;
						continue;
					}
					// #something else
				};
				default:
			} // switch (q.read)
		}
		flush(q.pos, false, true);
		if (errors != "") {
			parseError = errors;
			return null;
		} else return eventData;
	}
	//
	public static function init() {
		// define event names (used for GMS2 paths and when no name is available):
		for (i in 0 ... 16) linkType(i, "event" + i);
		linkType(0, "Create");
		linkType(1, "Destroy");
		linkType(2, "Alarm");
		linkType(3, "Step");
		linkType(4, "Collision");
		linkType(5, "Keyboard");
		linkType(6, "Mouse");
		linkType(7, "Other");
		linkType(8, "Draw");
		linkType(9, "KeyPress");
		linkType(10, "KeyRelease");
		linkType(11, "Trigger");
		linkType(12, "CleanUp");
		linkType(13, "Gesture");
		// set up auto-completion for events that have ":id" suffix:
		comp.push(new AceAutoCompleteItem("collision", "event"));
		comp.push(new AceAutoCompleteItem("keypress", "event"));
		comp.push(new AceAutoCompleteItem("keyrelease", "event"));
		comp.push(new AceAutoCompleteItem("keyboard", "event"));
		// read event names from the file:
		FileSystem.readTextFile(Main.relPath("api/events.gml"), function(err, data) {
			tools.ERegTools.each(~/^([\d-]+):([\d-]+)[ \t]+(\w+)/gm, data, function(rx:EReg) {
				var name = rx.matched(3);
				comp.push(new AceAutoCompleteItem(name, "event"));
				link(Std.parseInt(rx.matched(1)), Std.parseInt(rx.matched(2)), name);
			});
		});
	}
}
typedef GmlEventData = { type:Int, ?numb:Int, ?name:String, ?obj:yy.YyGUID };
typedef GmlEventList = Array<{ data:GmlEventData, code:Array<String> }>;
