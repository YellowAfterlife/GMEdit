package parsers;

import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlVersion;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeParser;
import js.RegExp.RegExpMatch;
import js.lib.RegExp;
import parsers.GmlSeekData.GmlSeekDataHint;
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
	public static function loadStd(src:String, data:GmlParseAPIArgs) {
		var stdKind = data.kind;
		var stdComp = data.comp;
		var stdDoc = data.doc;
		var stdTypes = data.types;
		var stdTypeExists = data.typeExists;
		var ukSpelling = data.ukSpelling;
		var kindPrefix = data.kindPrefix != null ? data.kindPrefix + "." : "";
		var version = data.version != null ? data.version : GmlVersion.none;
		var instComp = data.instComp;
		var instCompMap = data.instCompMap;
		var instKind = data.instKind;
		var instType = data.instType;
		var namespaceDefs = data.namespaceDefs;
		var typedefs = data.typedefs;
		var fieldHints = data.fieldHints;
		#if lwedit
		var lwArg0 = data.lwArg0;
		var lwArg1 = data.lwArg1;
		var lwInst = data.lwInst;
		var lwConst = data.lwConst;
		var lwFlags = data.lwFlags;
		#end
		var featureFlags = ui.Preferences.current.apiFeatureFlags;
		//
		
		// typedefs!
		var rxTypedef = new RegExp("^"
			+ "typedef\\s+"
			+ "(\\w+)"
			+ "(?:\\s*:\\s*(" + "\\w+(?:\\s*,\\s*\\w+)*" + "))?" // : parent(s)
			+ "(?:\\s*=\\s*(" + [
				"\\w+<\\s*" + "(?:\r?\n.*?)*?" + "\r?\n\\s*>", // multi-line declaration for specified_map or tuples
				".+",
			].join("|") + "))?" // = impl
		+ "", "gm");
		if (namespaceDefs != null || typedefs != null) rxTypedef.each(src, function(mt:RegExpMatch) {
			var name = mt[1];
			var parent = mt[2];
			var def = mt[3];
			var wantKind = true;
			stdComp.push(new AceAutoCompleteItem(name, "namespace", "type\nbuilt-in"));
			if (def != null) {
				if (typedefs != null) typedefs[name] = GmlTypeDef.parse(def, mt[0]);
			} else {
				if (namespaceDefs != null) {
					var def = new GmlNamespaceDef();
					def.name = name;
					def.parents = parent != null ? parent.splitRx(tools.JsTools.rx(~/\s*,\s*/)) : [];
					if (def.parents.indexOf("simplename") >= 0) wantKind = false;
					namespaceDefs.push(def);
				}
			}
			if (stdTypeExists != null) stdTypeExists[name] = true;
			if (wantKind) stdKind[name] = "namespace";
		});
		
		// struct types
		var rxStruct = new RegExp("^(?:" + [
				"(\\w+)" + "\\?" // 1 -> name
				+ "(?::(\\S+))?" // 2 -> type annotation
			, // alt:
				"\\?\\?" + "(\\w+)" // 3 -> namespace name
			].join("|") + ")"
			+ "(?://.*)?"
		+ "$", "gm");
		var currStruct = null;
		if (fieldHints != null)
		rxStruct.each(src, function(mt:RegExpMatch) {
			var name = mt[1];
			if (name == null) {
				name = mt[3];
				currStruct = name;
				stdKind[name] = "namespace";
				return;
			}
			var typeStr = mt[2];
			var type = GmlTypeDef.simple(typeStr);
			var cinf = "from " + currStruct;
			if (typeStr != null) cinf += "\ntype " + typeStr;
			var comp = new AceAutoCompleteItem(name, "variable", cinf);
			fieldHints.push(new GmlSeekDataHint(currStruct, true, name, comp, null, null, type)); 
		});
		
		var oldTypeWarn = GmlTypeParser.warnAboutMissing;
		var typeWarn = [];
		GmlTypeParser.warnAboutMissing = typeWarn;
		
		// functions!
		var rxFunc:RegExp = new RegExp("^"
			+ "(:*)" // $1 -> instance-specific marker (non-standard) - e.g. ":instance_copy(performevent)"
			+ "(\\w+" // function name
			+ "(?:<.*?>)?" // type params
			+ '\\(' // arguments start
			+ ".+" // rest of line
		+ ")", "gm");
		var rxFuncTail:RegExp = new RegExp("^"
			+ "(.*?)" // $1 -> normal stuff
			+ "([ ~\\$#*@&£!:]*)" // $2 -> flags (e.g. "£" for "draw_set_colour(col)£")
			+ "\\s*(?:\\^(\\w*))?" // $3 -> feature flag
			+ "\\s*"
			+ "(?://.*)?" // -> comment
		+ "$");
		var isGMS1 = version.config.docMode == "gms1";
		rxFunc.each(src, function(mt:RegExpMatch) {
			var doc = GmlFuncDoc.parse(mt[2]);
			for (name in typeWarn) Console.warn('[API] Unknown type $name referenced in ${mt[0]}');
			typeWarn.clear();
			var name = doc.name;
			var orig = name;
			
			var show = true;
			var mtt = rxFuncTail.exec(doc.post);
			var flags:String;
			if (mtt != null) {
				doc.post = mtt[1];
				flags = mtt[2];
				var featureFlag = mtt[3];
				if (featureFlag != null && !featureFlags.contains(featureFlag)) show = false;
			} else flags = "";
			
			if (flags.contains("&")) return; // deprecated!
			
			// UK/US spelling:
			if (isGMS1) {
				// were there other things..? Not like anyone cares
				var usn = NativeString.replaceExt(name, "colour", "color");
				if (ukSpelling) orig = usn; else name = usn;
				if (orig != name) {
					stdKind.set(orig, "function");
					stdDoc.set(orig, doc);
				}
			} else {
				if (flags.contains(ukSpelling ? "$" : "£")) show = false;
			}
			
			#if lwedit
			if (mt[1].length > 0 || flags.contains("@")) {
				lwInst.set(name, true);
				if (orig != name) lwInst.set(orig, true);
			}
			if (lwArg0 != null) {
				lwArg0[name] = doc.minArgs;
				lwArg1[name] = doc.maxArgs;
				if (orig != name) {
					lwArg0[orig] = doc.minArgs;
					lwArg1[orig] = doc.maxArgs;
				}
			}
			#end
			
			if (stdKind.exists(name)) return;
			
			stdKind[name] = kindPrefix + "function";
			if (show) stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: "function",
				doc: doc.getAcText()
			});
			stdDoc.set(name, doc);
		});
		
		// constants and variables!
		var rxVar = new RegExp("^"
			+ "(" // 1 -> comp
				+ "(\\w+)" // 2 -> name
				+ "(" + "\\[.*?\\]" + ")?" // 3 -> array data
				+ "([~\\*\\$£#@&]*)" // 4 -> flags
			+ ")"
			+ "(?:\\^(\\w*))?" // 5 -> feature flag
			+ "(?::(\\S+))?" // 6 -> type annotation
			+ "[ \t]*"
			+ "(?://.*)?" // a comment, perhaps?
			+ "$" // this is here because otherwise the regex greedily triggers on functions
		+ "", "gm");
		rxVar.each(src, function(mt:RegExpMatch) {
			var comp =  mt[1];
			var name =  mt[2];
			var range = mt[3];
			var flags = mt[4];
			var featureFlag = mt[5];
			var typeStr = mt[6];
			var type:GmlType = null;
			if (NativeString.contains(flags, "&")) return;
			if (typeStr != null && stdTypes != null) {
				type = GmlTypeDef.parse(typeStr, mt[0]);
				stdTypes[name] = type;
				for (name in typeWarn) Console.warn('[API] Unknown type $name referenced in ${mt[0]}');
				typeWarn.clear();
			}
			//
			var isConst:Bool = flags.indexOf("#") >= 0;
			var kind:String = isConst ? "constant" : "variable";
			var show = true;
			if (featureFlag != null && featureFlags.indexOf(featureFlag) < 0) show = false;
			//
			var isInst = NativeString.contains(flags, "@");
			if (isInst) {
				if (instComp != null) {
					var doc = "built-in";
					if (flags.contains("*")) doc += "\nread-only";
					if (range != null) doc += "\narray" + range;
					if (typeStr != null) doc += "\ntype" + typeStr;
					var c = new AceAutoCompleteItem(name, "variable", doc);
					instComp.push(c);
					instCompMap[name] = c;
				}
				if (instKind != null) instKind[name] = "variable";
				if (instKind != null && typeStr != null) instType[name] = type;
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
				if (isInst) lwBits |= 4;
				lwFlags.set(name, lwBits);
				if (orig != name) lwFlags.set(orig, lwBits);
			}
			#end
			stdKind.set(name, kindPrefix + kind);
			var doc = comp;
			if (typeStr != null) doc += "\ntype " + typeStr;
			if (show) stdComp.push({
				name: name,
				value: name,
				score: 0,
				meta: kind,
				doc: doc
			});
		});
		
		// `name = value` constants (for custom dialects)
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
typedef GmlParseAPIArgs = {
	kind:Dictionary<String>,
	doc:Dictionary<GmlFuncDoc>,
	comp:AceAutoCompleteItems,
	?typeExists:Dictionary<Bool>,
	?types:Dictionary<GmlType>,
	?namespaceDefs:Array<GmlNamespaceDef>,
	?typedefs:Dictionary<GmlType>,
	?ukSpelling:Bool,
	?version:GmlVersion,
	?kindPrefix:String,
	?instComp:AceAutoCompleteItems,
	?instCompMap:Dictionary<AceAutoCompleteItem>,
	?instKind:Dictionary<AceTokenType>,
	?instType:Dictionary<GmlType>,
	?fieldHints:Array<GmlSeekDataHint>,
	#if lwedit
	?lwArg0:Dictionary<Int>,
	?lwArg1:Dictionary<Int>,
	?lwConst:Dictionary<Bool>,
	?lwFlags:Dictionary<Int>,
	?lwInst:Dictionary<Bool>,
	#end
};