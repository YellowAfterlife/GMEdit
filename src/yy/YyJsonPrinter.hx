package yy;
import js.lib.RegExp;
import haxe.DynamicAccess;
import haxe.Int64;
import haxe.Json;
import haxe.ds.ObjectMap;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class YyJsonPrinter {
	//{ the following are set in stringify() call and reused
	static var isExt:Bool = false;
	static var wantCompact:Bool = false;
	static var trailingCommas:Bool = false;
	static var wantPrefixFields:Bool = false;
	static var isGM2023:Bool = false;
	static var isGM2024:Bool = false;
	//}
	
	static function stringify_string(s:String):String {
		var r = '"';
		var start = 0;
		for (i in 0 ... s.length) {
			var esc:String;
			switch (StringTools.fastCodeAt(s, i)) {
				case '"'.code: esc = '\\"';
				case '/'.code: esc = isExt ? "/" : '\\/';
				case '\\'.code: esc = '\\\\';
				case '\n'.code: esc = '\\n';
				case '\r'.code: esc = '\\r';
				case '\t'.code: esc = '\\t';
				case 8: esc = '\\b';
				case 12: esc = '\\f';
				default: esc = null;
			}
			if (esc != null) {
				if (i > start) {
					r += s.substring(start, i) + esc;
				} else r += esc;
				start = i + 1;
			}
		}
		if (start == 0) return '"$s"';
		if (start < s.length) {
			return r + s.substring(start) + '"';
		} else return r + '"';
	}
	
	public static var mvcOrder22 = ["configDeltas", "id", "modelName", "mvc", "name"];
	public static var mvcOrder23 = ["parent", "resourceVersion", "name", "path", "tags", "resourceType"];
	public static final emptyOrder:Array<String> = [];
	
	/** in projects with resourceVersion >= 1.6, these appear before everything else */
	public static var rv1_6_prefixFieldList = ["resourceType", "resourceVersion", "name"];
	public static var rv1_6_prefixFieldMap:Dictionary<Bool> = Dictionary.fromKeys(rv1_6_prefixFieldList, true);
	
	public static var orderByModelName:Dictionary<Array<String>> = (function() {
		var q = new Dictionary();
		var plain = ["id", "modelName", "mvc"];
		q["GMExtensionFunction"] = plain.concat([]);
		q["GMEvent"] = plain.concat(["IsDnD"]);
		return q;
	})();
	/** <=2.2 */
	public static var metaByModelName:Dictionary<YyJsonMeta> = @:privateAccess YyJsonMeta.initByModelName();
	/** 2.3 .. 2022 */
	public static var metaByResourceType:Dictionary<YyJsonMeta> = @:privateAccess YyJsonMeta.initByResourceType();
	/** >=2023 */
	public static var metaByResourceType2023:Dictionary<YyJsonMeta> = @:privateAccess YyJsonMeta.initByResourceType2023();
	
	static var isOrderedCache:Map<Array<String>, Dictionary<Bool>> = new Map();
	
	static function fieldComparator_fallback(a:String, b:String) {
		a = a.toLowerCase();
		b = b.toLowerCase();
		if (isGM2024) {
			static var underscores = new RegExp("_", "g");
			a = a.replaceExt(underscores, "|");
			b = b.replaceExt(underscores, "|");
		}
		return a < b ? -1 : 1;
	}
	
	static var fieldComparator_intl = (function() {
		try {
			var cl = new js.lib.intl.Collator();
			return cl.compare;
		} catch (_) {
			return null;
		}
	})();
	
	static function fieldComparator(a, b) {
		if (isGM2023 && !isGM2024) {
			// https://github.com/YoYoGames/GameMaker-Bugs/issues/4713#issuecomment-1961910024
			if (a == "resourceType") return -1;
			if (b == "resourceType") return 1;
			if (a == "resourceVersion") return -1;
			if (b == "resourceVersion") return 1;
			if (a == "name") return -1;
			if (b == "name") return 1;
		}
		if (a == b) return 0;
		//
		if (!isGM2024 && fieldComparator_intl != null) return fieldComparator_intl(a, b);
		//
		a = a.toLowerCase();
		b = b.toLowerCase();
		if (isGM2024) {
			static var underscores = new RegExp("_", "g");
			a = a.replaceExt(underscores, "|");
			b = b.replaceExt(underscores, "|");
		}
		return a < b ? -1 : 1;
	}
	
	static var indentString:String = "    ";
	static var nextType:String = null;
	#if js
	static var _Int64:Class<Dynamic> = null;
	#end
	static function stringify_rec(obj:Dynamic, indent:Int, compact:Bool, ?digits:Int):String {
		var nt:String = nextType; nextType = null;
		if (obj == null) { // also hits "undefined"
			return "null";
		}
		else if (Std.is(obj, String)) {
			return stringify_string(obj);
		}
		else if (Std.is(obj, Array)) {
			var indentString = YyJsonPrinter.indentString;
			var arr:Array<Dynamic> = obj;
			var len = arr.length;
			var wantedCompact = YyJsonPrinter.wantCompact;
			if (len == 0 && wantedCompact) return "[]";
			var r = "[\r\n" + indentString.repeat(++indent);
			for (i in 0 ... arr.length) {
				nextType = nt;
				if (wantedCompact) {
					if (i > 0) r += "\r\n" + indentString.repeat(indent);
					r += stringify_rec(arr[i], indent, true) + ",";
				} else {
					if (i > 0) r += ",\r\n" + indentString.repeat(indent);
					r += stringify_rec(arr[i], indent, compact);
				}
			}
			return r + "\r\n" + indentString.repeat(--indent) + "]";
		}
		else if (Reflect.isObject(obj)) {
			if (obj.__int64) return "" + (obj:Int64);
			#if js
			if (_Int64 != null && js.Syntax.instanceof(obj, _Int64)) return "" + (obj:Int64);
			#end
			var indentString = YyJsonPrinter.indentString;
			indent += 1;
			var r = (compact ? "{" : "{\r\n" + indentString.repeat(indent));
			var orderedFields = (obj:YyBase).hxOrder;
			var fieldDigits = (obj:YyBase).hxDigits;
			var fieldTypes:Dictionary<String> = null;
			var found = 0, sep = false;
			// where available, use meta
			var meta:YyJsonMeta;
			var _2024 = isGM2024;
			var _2023 = !_2024 && isExt && isGM2023;
			if (_2024) {
				meta = null;
				if (Reflect.field(obj, "%Name") == null && obj.resourceType != null) {
					var tfd = "$" + obj.resourceType;
					if (!Reflect.hasField(obj, tfd)) Reflect.setField(obj, tfd, "");
					Reflect.setField(obj, "%Name", obj.name ?? "");
				}
			} else if (nt != null) {
				meta = isExt ? (_2023 ? metaByResourceType2023[nt] : metaByResourceType[nt]) : metaByModelName[nt];
				if (meta == null) Main.console.warn('Unknown type $nt');
			} else if (isExt) {
				nt = obj.resourceType;
				meta = JsTools.nca(nt, (_2023 ? metaByResourceType2023[nt] : metaByResourceType[nt]));
			} else {
				nt = obj.modelName;
				meta = JsTools.nca(nt, metaByModelName[nt]);
			}
			//
			if (_2024) {
				orderedFields = emptyOrder;
			} else if (meta != null) {
				orderedFields = meta.order;
				fieldTypes = meta.types;
				fieldDigits = meta.digits;
			} else if (orderedFields == null) {
				if (Reflect.hasField(obj, "mvc")) {
					orderedFields = orderByModelName[obj.modelName];
				}
				if (orderedFields == null) {
					orderedFields = isExt ? mvcOrder23 : mvcOrder22;
				}
			} else if (Reflect.hasField(obj, "mvc") || Reflect.hasField(obj, "resourceType")) found++;
			//
			var isOrdered:Dictionary<Bool> = isOrderedCache[orderedFields];
			if (isOrdered == null) {
				isOrdered = new Dictionary();
				isOrdered["hxOrder"] = true;
				isOrdered["hxDigits"] = true;
				for (field in orderedFields) isOrdered[field] = true;
				isOrderedCache[orderedFields] = isOrdered;
			}
			//
			var tcs = trailingCommas;
			var orderedFieldsAfter = isExt && !_2023;
			inline function addSep():Void {
				if (!tcs) {
					if (sep) r += ",\r\n" + indentString.repeat(indent); else sep = true;
				} else if (!compact) {
					if (sep) r += "\r\n" + indentString.repeat(indent); else sep = true;
				}
			}
			function addField(field:String):Void {
				addSep();
				found++;
				r += stringify_string(field) + (compact || isGM2024 ? ":" : ": ");
				nextType = fieldTypes != null ? fieldTypes[field] : null;
				r += stringify_rec(Reflect.field(obj, field), indent, compact,
					fieldDigits != null ? fieldDigits[field] : null
				);
				if (tcs) r += ",";
			}
			
			// with 2022.8/YYP resourceVersion>=1.6, key fields (type, name, version)
			// appear before everything else.
			if (wantPrefixFields) for (field in rv1_6_prefixFieldList) {
				if (!Reflect.hasField(obj, field)) continue;
				addField(field);
			}
			
			// if ordered fields should go after the regular ones,
			// we'll swap result-string 
			var rOrig:String, rAfter:String;
			if (orderedFieldsAfter) {
				rOrig = r; r = "";
			} else rOrig = null;
			
			//
			for (field in orderedFields) {
				if (!Reflect.hasField(obj, field)) continue;
				if (wantPrefixFields && rv1_6_prefixFieldMap.exists(field)) continue;
				addField(field);
			}
			//
			if (orderedFieldsAfter) {
				rAfter = r;
				r = rOrig;
			} else rAfter = null;
			//
			var allFields = Reflect.fields(obj);
			if (allFields.length > found) {
				allFields.sort(fieldComparator);
				if (orderedFieldsAfter) sep = false;
				for (field in allFields) {
					if (isOrdered.exists(field)) continue;
					addField(field);
				}
				if (orderedFieldsAfter && rAfter != "") {
					addSep();
					r += rAfter;
				}
			} else {
				if (orderedFieldsAfter) r += rAfter;
			}
			//
			indent -= 1;
			return r + (compact ? "}" : "\r\n" + indentString.repeat(indent) + "}");
		}
		else {
			if (digits != null && Std.is(obj, Int)) {
				return obj + "." + NativeString.repeat("0", digits);
			} else return Json.stringify(obj);
		}
	}
	
	public static function stringify(obj:Dynamic, extJson:Bool = false):String {
		wantCompact = extJson;
		trailingCommas = extJson;
		isExt = extJson;
		#if js
		var project = gml.Project.current;
		if (project != null) {
			isGM2023 = project.isGM2023;
			isGM2024 = project.isGM2024;
			wantPrefixFields = !isGM2023 && project.yyResourceVersion >= 1.6;
		} else {
			wantPrefixFields = false;
			isGM2023 = false;
			isGM2024 = false;
		}
		#end
		indentString = extJson ? "  " : "    ";
		return stringify_rec(obj, 0, false);
	}
	
	public static function init() {
		#if js
		_Int64 = Type.resolveClass("haxe._Int64.___Int64");
		if (_Int64 == null) Console.error("Couldn't find Int64 implementation!");
		#end
	}
}
