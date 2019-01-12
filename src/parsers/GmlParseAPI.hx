package parsers;

import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlVersion;
import tools.Dictionary;
import ace.AceWrap;
import ace.extern.*;
import tools.NativeString;
using tools.ERegTools;

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
		?ukSpelling:Bool,
		?version:GmlVersion,
		?kindPrefix:String,
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
		var ukSpelling = data.ukSpelling;
		var kindPrefix = data.kindPrefix != null ? data.kindPrefix + "." : "";
		var version = data.version != null ? data.version : GmlVersion.none;
		#if lwedit
		var lwArg0 = data.lwArg0;
		var lwArg1 = data.lwArg1;
		var lwInst = data.lwInst;
		var lwConst = data.lwConst;
		var lwFlags = data.lwFlags;
		#end
		//  : 1func (2args ) 3flags
		~/^(:*(\w+)\((.*?)\))([~\$#*@&£!:]*);?[ \t]*$/gm.each(src, function(rx:EReg) {
			var comp = rx.matched(1);
			var name = rx.matched(2);
			var args = rx.matched(3);
			var flags:String = rx.matched(4);
			if (NativeString.contains(flags, "&")) return;
			//
			var orig = name;
			var show = true;
			var doc = GmlFuncDoc.parse(comp);
			if (version == GmlVersion.v2) {
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
		// 1name 2array       3flags         type
		~/^((\w+)(\[[^\]]*\])?([~\*\$£#@&]*))(?::\w+)?;?[ \t]*$/gm.each(src, function(rx:EReg) {
			var comp = rx.matched(1);
			var name = rx.matched(2);
			var flags = rx.matched(4);
			if (NativeString.contains(flags, "&")) return;
			//
			var isConst:Bool = flags.indexOf("#") >= 0;
			var kind:String = isConst ? "constant" : "variable";
			//
			var orig = name;
			if (version != GmlVersion.v2 && version != GmlVersion.none) {
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
				if (rx.matched(3) != null) lwBits |= 2;
				if (NativeString.contains(flags, "@")) lwBits |= 4;
				lwFlags.set(name, lwBits);
				if (orig != name) lwFlags.set(orig, lwBits);
			}
			#end
			stdKind.set(name, kindPrefix + kind);
			stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: kind,
				doc: comp
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
