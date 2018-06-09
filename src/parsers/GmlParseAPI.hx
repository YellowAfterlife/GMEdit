package parsers;

import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlVersion;
import tools.Dictionary;
import ace.AceWrap;
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
		?lwArgc:Dictionary<Int>,
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
		var lwArgc = data.lwArgc;
		var lwInst = data.lwInst;
		var lwConst = data.lwConst;
		var lwFlags = data.lwFlags;
		#end
		//  : 1func (2args ) 3flags
		~/^(:?(\w+)\((.*?)\))([~\$#*@&£!:]*);?[ \t]*$/gm.each(src, function(rx:EReg) {
			var comp = rx.matched(1);
			var name = rx.matched(2);
			var args = rx.matched(3);
			var flags:String = rx.matched(4);
			if (NativeString.contains(flags, "&")) return;
			#if lwedit
			if (lwInst != null && (
				comp.charCodeAt(0) == ":".code || NativeString.contains(flags, "@")
			)) lwInst.set(name, true);
			if (lwArgc != null) {
				if (NativeString.contains(args, "...") || NativeString.contains(args, "?")) {
					lwArgc.set(name, -1);
				} else if (NativeString.contains(args, ",")) {
					lwArgc.set(name, args.split(",").length);
				} else {
					lwArgc.set(name, NativeString.trimBoth(args).length > 0 ? 1 : 0);
				}
			}
			#end
			var show = true;
			var doc = GmlFuncDoc.parse(comp);
			if (version == GmlVersion.v2) {
				if (ukSpelling) {
					if (flags.indexOf("$") >= 0) show = false;
				} else {
					if (flags.indexOf("£") >= 0) show = false;
				}
			} else if (version != GmlVersion.none && !ukSpelling) {
				var orig = name;
				// (todo: were there other things?)
				name = NativeString.replaceExt(name, "colour", "color");
				if (orig != name) {
					stdKind.set(orig, "function");
					stdDoc.set(name, doc);
				}
			}
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
			var kind:String;
			if (flags.indexOf("#") >= 0) {
				kind = "constant";
				#if lwedit
				if (lwConst != null) lwConst.set(name, true);
				#end
			} else kind = "variable";
			#if lwedit
			if (lwFlags != null) {
				var lwBits = 0x0;
				if (NativeString.contains(flags, "*")) lwBits |= 1;
				if (rx.matched(3) != null) lwBits |= 2;
				if (NativeString.contains(flags, "@")) lwBits |= 4;
				lwFlags.set(name, lwBits);
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
