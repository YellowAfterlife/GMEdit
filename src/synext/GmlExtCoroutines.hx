package synext;
import ace.AceWrap;
import gml.GmlAPI;
import haxe.DynamicAccess;
import js.html.ScriptElement;
import js.html.Console;
import js.lib.RegExp;
import tools.Dictionary;
import ui.Preferences;
import ace.extern.*;
import parsers.GmlReader;
using StringTools;

/**
 * Handles conversion from/to #gmcr magic.
 * @author YellowAfterlife
 */
class GmlExtCoroutines {
	public static inline var arrayTypeName = "coroutine_array";
	public static inline var arrayTypeResultName = "coroutine_array_result";
	private static var keywordMap0:Dictionary<AceTokenType> = new Dictionary();
	private static var keywordMap1:Dictionary<AceTokenType> = Dictionary.fromKeys(
		["yield", "label", "goto"], "keyword");
	public static var keywordMap:Dictionary<AceTokenType> = keywordMap0;
	public static var enabled:Bool = false;
	public static inline var constructorSuffix = "_coroutine";
	public static inline var endComment = "*\\endco\\/";
	public static inline function constructorFor(name:String) {
		return name + constructorSuffix;
	}
	
	/**
	 * Metadata from the last pre/post run, if any
	 * Contains mode/yieldScripts
	 */
	public static var result:GmlExtCoroutinesResult = null;
	
	public static inline function update(enable:Bool) {
		enabled = enable;
		keywordMap = enable ? keywordMap1 : keywordMap0;
	}
	public static function ensureScript() {
		var scr:ScriptElement = cast Main.document.getElementById("gmcr_script");
		if (scr.src == null || scr.src == "") {
			scr.src = "./misc/gmcr.js";
		}
	}
	//
	private static inline var prefix = "/*//!#gmcr";
	private static inline var suffix = "//!#gmcr*/";
	private static inline var jsdStart = "\n// @gmcr ";
	public static var preResult:GmlExtCoroutinesResult = null;
	public static function pre(gml:String):String {
		result = null;
		if (!Preferences.current.coroutineMagic) return gml;
		var orig = gml;
		gml = {
			var pos0 = gml.indexOf(prefix);
			if (pos0 < 0) return gml;
			var pos1 = gml.indexOf(suffix);
			if (pos1 < 0) pos1 = gml.length;
			//
			pos0 += prefix.length;
			if (gml.fastCodeAt(pos0) == "\r".code) pos0 += 1;
			if (gml.fastCodeAt(pos0) == "\n".code) pos0 += 1;
			if (gml.fastCodeAt(pos1 - 1) == "\n".code) pos1 -= 1;
			if (gml.fastCodeAt(pos1 - 1) == "\r".code) pos1 -= 1;
			//
			gml.substring(pos0, pos1);
		};
		gml = gml.replace(endComment, "*/");
		var version = GmlAPI.version;
		var q = new GmlReader(gml);
		var out = "";
		var start = 0;
		inline function flush(till:Int):Void {
			out += q.substring(start, till);
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: {
						//flush(q.pos);
						//start = ++q.pos;
						while (q.loop) {
							c = q.read();
							if (c == "*".code
								&& q.peek() == "\\".code
								&& q.peek(1) == "/".code
							) {
								flush(q.pos);
								start = ++q.pos;
								q.pos += 1;
								break;
							}
						}
					};
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): q.skipDqTplString(version);
				default: { };
			}
		}
		flush(q.pos);
		
		//
		var mdPos = orig.lastIndexOf(jsdStart);
		var meta:GmlExtCoroutinesResult = null;
		if (mdPos >= 0) {
			var mdStart = mdPos + jsdStart.length;
			var mdEnd = orig.indexOf("\n", mdStart);
			if (mdEnd < 0) mdEnd = orig.length;
			try {
				meta = haxe.Json.parse(orig.substring(mdStart, mdEnd));
			} catch (x:Dynamic) {
				Console.error("Error parsing gmcr meta:", x);
			}
		}
		if (meta == null) {
			Console.log("No #gmcr meta - running post");
			// if there's no meta, run post-build to get it
			post(out);
		} else {
			result = meta;
		}
		return out;
	}
	public static var errorText:String;
	private static var markRx = new RegExp("^[ \t]*#gmcr", "m");
	public static function post(code:String):String {
		result = null;
		if (!Preferences.current.coroutineMagic) return code;
		if (!markRx.test(code)) return code;
		var found = false;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		var mode:String = null;
		var macroList = [];
		var macroMap = new Dictionary();
		inline function flush(till:Int):Void {
			out += q.substring(start, till);
		}
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): q.skipDqTplString(version);
				case "#".code if (q.substr(p, 5) == "#gmcr"): {
					var l = p;
					found = true;
					while (--l >= 0) {
						switch (q.get(l)) {
							case " ".code, "\t".code: // OK!
							case "\n".code: break;
							default: found = false; break;
						}
					}
					if (found) {
						q.skip(4);
						q.skipSpaces0();
						mode = q.readIdent();
					}
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					var name = q.substring(p, q.pos);
					var m = GmlAPI.gmlMacros[name];
					if (m != null && !macroMap.exists(name)) {
						macroMap[name] = m;
						macroList.push(name);
					}
				};
				default: { };
			}
		}
		if (!found) return code;
		flush(q.pos);
		
		var proc:String->GmlExtCoroutinesOptions->GmlExtCoroutinesResult = untyped window.gmcr_proc;
		if (proc == null) {
			errorText = "GMCR is unavailable or didn't load up yet.\n"
				+ "If you are compiling GMEdit from source code, you'll want to copy it from an itch.io release";
			return null;
		}
		
		var canMethod = version.hasFunctionLiterals();
		if (mode == null) mode = canMethod ? "constructor" : "linear";
		switch (mode) {
			case "linear", "method", "constructor": {}
			default: errorText = '"$mode" is not a known #gmcr mode.'; return null;
		}
		if (mode != "linear" && !canMethod) {
			errorText = "Can't use \"method\" #gmcr mode in this GameMaker version";
			return null;
		}
		var ver = canMethod ? 23 : version.hasStringEscapeCharacters() ? 2 : 1;
		//
		var functions = GmlAPI.stdDoc.keys();
		functions = functions.concat(GmlAPI.gmlDoc.keys());
		//
		var globalvars = [];
		for (vn => entry in GmlAPI.stdKind) {
			switch (entry) {
				case "variable":
					if (GmlAPI.stdInstKind.exists(vn)) continue;
					globalvars.push(vn);
				case "constant":
					globalvars.push(vn);
			}
		}
		//
		var macros = [];
		for (k in macroList) {
			macros.push({ name: k, code: macroMap[k].expr });
		}
		//
		//trace(out);
		var pair = proc(out, {
			version: ver,
			mode: mode,
			functions: functions,
			globalvars: globalvars,
			macros: macros
		});
		if (pair.code == null) {
			errorText = "Coroutine compilation failed:\n" + pair.error;
			return null;
		}
		result = pair;
		out = out.replace("*/", endComment);
		return pair.code + "\r\n" + prefix + "\r\n" + out + "\r\n" + suffix + "\r\n";
	}
}
enum abstract GmlExtCoroutineMode(String) from String to String {
	var Linear = "linear";
	var Method = "method";
	var Constructor = "constructor";
}
private typedef GmlExtCoroutinesResult = {
	code:String,
	error:String,
	?mode:String,
	?yieldScripts:Array<String>,
};
private typedef GmlExtCoroutinesOptions = {
	version:Int,
	mode:String,
	functions:Array<String>,
	globalvars:Array<String>,
	macros:Array<{name:String, code:String}>,
};
