package yy;
import haxe.Json;
import haxe.ds.ObjectMap;
import tools.Dictionary;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class YyJsonPrinter {
	static var isExt:Bool = false;
	static var wantCompact:Bool = false;
	static var trailingCommas:Bool = false;
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
	
	public static var mvcOrder = ["configDeltas", "id", "modelName", "mvc", "name"];
	public static var orderByModelName:Dictionary<Array<String>> = (function() {
		var q = new Dictionary();
		var plain = ["id", "modelName", "mvc"];
		q["GMExtensionFunction"] = plain.concat([]);
		q["GMEvent"] = plain.concat(["IsDnD"]);
		return q;
	})();
	
	static var isOrderedCache:Map<Array<String>, Dictionary<Bool>> = new Map();
	
	static function fieldComparator(a:String, b:String):Int {
		return a > b ? 1 : -1;
	}
	
	static var indentString:String = "    ";
	static function stringify_rec(obj:Dynamic, indent:Int, compact:Bool):String {
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
			var indentString = YyJsonPrinter.indentString;
			var r = (compact ? "{" : "{\r\n" + indentString.repeat(++indent));
			var orderedFields:Array<String> = Reflect.field(obj, "hxOrder");
			var found = 0, sep = false;
			if (orderedFields == null) {
				if (Reflect.hasField(obj, "mvc")) {
					orderedFields = orderByModelName[Reflect.field(obj, "modelName")];
				}
				if (orderedFields == null) orderedFields = mvcOrder;
			} else found++;
			//
			var isOrdered:Dictionary<Bool> = isOrderedCache[orderedFields];
			if (isOrdered == null) {
				isOrdered = new Dictionary();
				isOrdered["hxOrder"] = true;
				for (field in orderedFields) isOrdered[field] = true;
				isOrderedCache[orderedFields] = isOrdered;
			}
			//
			var tcs = trailingCommas;
			inline function addField(field:String):Void {
				if (!tcs) {
					if (sep) r += ",\r\n" + indentString.repeat(indent); else sep = true;
				} else if (!compact) {
					if (sep) r += "\r\n" + indentString.repeat(indent); else sep = true;
				}
				found++;
				r += stringify_string(field) + (compact ? ":" : ": ")
					+ stringify_rec(Reflect.field(obj, field), indent, compact);
				if (tcs) r += ",";
			}
			//
			for (field in orderedFields) {
				if (!Reflect.hasField(obj, field)) continue;
				addField(field);
			}
			//
			var allFields = Reflect.fields(obj);
			if (allFields.length > found) {
				allFields.sort(fieldComparator);
				for (field in allFields) {
					if (isOrdered.exists(field)) continue;
					addField(field);
				}
			}
			return r + (compact ? "}" : "\r\n" + indentString.repeat(--indent) + "}");
		}
		else {
			return Json.stringify(obj);
		}
	}
	
	public static function stringify(obj:Dynamic, extJson:Bool = false):String {
		wantCompact = extJson;
		trailingCommas = extJson;
		isExt = extJson;
		indentString = extJson ? "  " : "    ";
		return stringify_rec(obj, 0, false);
	}
}
