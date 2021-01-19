package parsers;

import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlVersion;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeParser;
import js.RegExp.RegExpMatch;
import js.lib.RegExp;
import tools.Dictionary;
import ace.AceWrap;
import ace.extern.*;
import tools.NativeString;
using tools.NativeString;
using tools.NativeArray;
using tools.ERegTools;
using tools.RegExpTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlParseAPI {
	/**
	 * Loads definitions from fnames format used by GMS itself.
	 */
	public static function loadStd(src:String, data:{
		kind:Dictionary<String>,
		doc:Dictionary<GmlFuncDoc>,
		comp:AceAutoCompleteItems,
		?types:Dictionary<GmlType>,
		?namespaceDefs:Array<GmlNamespaceDef>,
		?ukSpelling:Bool,
		?version:GmlVersion,
		?kindPrefix:String,
		?instComp:AceAutoCompleteItems,
		#if lwedit
		?lwArg0:Dictionary<Int>,
		?lwArg1:Dictionary<Int>,
		?lwConst:Dictionary<Bool>,
		?lwFlags:Dictionary<Int>,
		?lwInst:Dictionary<Bool>,
		#end
	}) {
		var stdKind = data.kind;
		var stdComp = data.comp;
		var stdDoc = data.doc;
		var stdTypes = data.types;
		var ukSpelling = data.ukSpelling;
		var kindPrefix = data.kindPrefix != null ? data.kindPrefix + "." : "";
		var version = data.version != null ? data.version : GmlVersion.none;
		var instComp = data.instComp;
		var namespaceDefs = data.namespaceDefs;
		#if lwedit
		var lwArg0 = data.lwArg0;
		var lwArg1 = data.lwArg1;
		var lwInst = data.lwInst;
		var lwConst = data.lwConst;
		var lwFlags = data.lwFlags;
		#end
		//
		
		// typedefs!
		var rxTypedef = new RegExp("^"
			+ "typedef\\s+"
			+ "(\\w+)"
			+ "(?:\\s*:\\s*(\\w+))?" // : parent
		+ "", "gm");
		if (namespaceDefs != null) rxTypedef.each(src, function(mt:RegExpMatch) {
			var name = mt[1];
			var parent = mt[2];
			namespaceDefs.push({ name: name, parent: parent });
			stdKind[name] = "namespace";
			stdComp.push(new AceAutoCompleteItem(name, "namespace", "type\nbuilt-in"));
		});
		
		var oldTypeWarn = GmlTypeParser.warnAboutMissing;
		var typeWarn = [];
		GmlTypeParser.warnAboutMissing = typeWarn;
		
		// functions!
		var rxFunc:RegExp = new RegExp("^"
			+ "(" // $1 -> general signature
				+ ":*" // instance variable marker
				+ "(\\w+)" // $2 -> name
				+ "(?:<.*?>)?" // type params
				+ "\\(" + "(.*?)" + "\\)" // $3 -> args
				+ "(?:->" + "(\\S+)" + ")?" // $4 -> retType
			+ ")"
			+ "([ ~\\$#*@&£!:]*)" // $5 -> flags
		+ "", "gm");
		rxFunc.each(src, function(mt:RegExpMatch) {
			var comp = mt[1];
			var name = mt[2];
			var args = mt[3];
			var ret = mt[4];
			var flags:String = mt[5];
			if (NativeString.contains(flags, "&")) return;
			//
			var orig = name;
			var show = true;
			var doc = GmlFuncDoc.parse(comp);
			for (name in typeWarn) Console.warn('[API] Unknown type $name referenced in', mt[0]);
			typeWarn.clear();
			//
			if (version.config.docMode != "gms1") {
				if (ukSpelling) {
					if (flags.indexOf("$") >= 0) show = false;
				} else {
					if (flags.indexOf("£") >= 0) show = false;
				}
			} else if (version != GmlVersion.none) {
				// (todo: were there other things?)
				var usn = NativeString.replaceExt(name, "colour", "color");
				if (ukSpelling) orig = usn; else name = usn;
				if (orig != name) {
					stdKind.set(orig, "function");
					stdDoc.set(orig, doc);
				}
			}
			//
			#if lwedit
			if (lwInst != null && (
				comp.charCodeAt(0) == ":".code || NativeString.contains(flags, "@")
			)) {
				lwInst.set(name, true);
				if (orig != name) lwInst.set(orig, true);
			}
			if (lwArg0 != null) {
				var argc:Int;
				if (NativeString.contains(args, "...") || NativeString.contains(args, "?")) {
					argc = -1;
				} else if (NativeString.contains(args, ",")) {
					argc = args.split(",").length;
				} else {
					argc = NativeString.trimBoth(args).length > 0 ? 1 : 0;
				}
				var arg0:Int, arg1:Int;
				if (argc == -1) {
					arg0 = 0;
					arg1 = 0x7fffffff;
				} else {
					arg0 = argc;
					arg1 = argc;
				}
				lwArg0.set(name, arg0);
				lwArg1.set(name, arg1);
				if (orig != name) {
					lwArg0.set(orig, arg0);
					lwArg1.set(orig, arg1);
				}
			}
			#end
			//
			if (stdKind.exists(name)) return;
			stdKind.set(name, kindPrefix + "function");
			if (show) stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "function",
				doc: comp
			});
			stdDoc.set(name, doc);
		});
		
		// variables!
		var rxVar = new RegExp("^"
			+ "(" // 1 -> comp
				+ "(\\w+)" // 2 -> name
				+ "(" + "\\[.*?\\]" + ")?" // 3 -> array data
				+ "([~\\*\\$£#@&]*)" // 4 -> flags
			+ ")"
			+ "(?::(\\S+))?" // 5 -> type annotation
		+ "", "gm");
		rxVar.each(src, function(mt:RegExpMatch) {
			var comp =  mt[1];
			var name =  mt[2];
			var range = mt[3];
			var flags = mt[4];
			var type =  mt[5];
			if (NativeString.contains(flags, "&")) return;
			if (type != null && stdTypes != null) {
				stdTypes[name] = GmlTypeDef.parse(type);
				for (name in typeWarn) Console.warn('[API] Unknown type $name referenced in', mt[0]);
				typeWarn.clear();
			}
			//
			var isConst:Bool = flags.indexOf("#") >= 0;
			var kind:String = isConst ? "constant" : "variable";
			//
			if (instComp != null
				&& NativeString.contains(flags, "@")
			) {
				var doc = "built-in";
				if (flags.contains("*")) doc += "\nread-only";
				if (range != null) doc += "\narray" + range;
				instComp.push(new AceAutoCompleteItem(name, "variable", doc));
			}
			//
			var orig = name;
			if (version.config.docMode == "gms1") {
				// (todo: were there other things?)
				var usn = NativeString.replaceExt(name, "colour", "color");
				if (ukSpelling) orig = usn; else name = usn;
				if (orig != name) stdKind.set(orig, kindPrefix + kind);
			}
			//
			#if lwedit
			if (isConst && lwConst != null) {
				lwConst.set(name, true);
				if (orig != name) lwConst.set(orig, true);
			}
			if (lwFlags != null) {
				var lwBits = 0x0;
				if (NativeString.contains(flags, "*")) lwBits |= 1;
				if (range != null) lwBits |= 2;
				if (NativeString.contains(flags, "@")) lwBits |= 4;
				lwFlags.set(name, lwBits);
				if (orig != name) lwFlags.set(orig, lwBits);
			}
			#end
			stdKind.set(name, kindPrefix + kind);
			var doc = comp;
			if (type != null) doc += "\ntype " + type;
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: kind,
				doc: doc
			});
		});
		// name       =      value
		~/^(\w+)[ \t]*=[ \t]*(.+)$/gm.each(src, function(rx:EReg) {
			var name = rx.matched(1);
			var expr = rx.matched(2);
			stdKind.set(name, kindPrefix + "constant");
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "constant",
				doc: expr
			});
		});
		//
		GmlTypeParser.warnAboutMissing = oldTypeWarn;
	}
	
	public static function loadAssets(src:String, out:{
		kind:Dictionary<String>,
		comp:AceAutoCompleteItems,
	}) {
		var stdKind = out.kind;
		var stdComp = out.comp;
		~/(\w+)/g.each(src, function(rx:EReg) {
			var name = rx.matched(1);
			stdKind.set(name, "asset");
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "asset",
				doc: null,
			});
		});
	}
}
