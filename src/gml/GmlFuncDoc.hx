package gml;
import gml.funcdoc.*;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import gml.type.GmlTypeTemplateItem;
import js.lib.RegExp;
import parsers.GmlReader;
import tools.CharCode;
import tools.Aliases;
import tools.JsTools;
import tools.NativeArray;
import tools.RegExpCache;
using StringTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFuncDoc {
	
	public static inline var retArrow:String = "➜";
	public static inline var parRetArrow:String = ")➜";
	public static inline function patchArrow(s:String):String {
		return StringTools.replace(s, "->", retArrow);
	}
	
	public var name:String;
	
	/** "func(" */
	public var pre:String;
	
	/** "): doc" */
	public var post:String;
	
	/** an array of argument names */
	public var args:Array<String>;
	
	public var argTypes:Array<GmlType> = null;
	
	public var hasReturn:Bool = null;
	
	/**
	 * Whether this is a 2.3 `function(...) constructor`
	 * (implications: should only be called via `new`, does not need to return)
	 */
	public var isConstructor:Bool = false;
	
	/** If this is a 2.3 constructor and it inherits from another, this is the name of that */
	public var parentName:String = null;
	
	/** Type of `self` set via `/// @self` */
	public var selfType:GmlType = null;
	
	var minArgsCache:Null<Int> = null;
	
	static var rxIsOpt:RegExp = new RegExp("^\\s*(?:"
		+ "\\[" // [arg]
		+ "|\\?" // ?arg
		+ "|\\.\\.\\." // ...rest
	+ ")");
	public var minArgs(get, never):Int;
	private function get_minArgs():Int {
		if (minArgsCache != null) return minArgsCache;
		var argi = args.length;
		while (argi > 0) {
			var arg = args[argi - 1];
			if (arg == null
				|| rxIsOpt.test(arg)
				|| arg.endsWith("*")
				|| arg.contains("=")
				|| arg.contains("optional")
			) {
				argi--;
			} else if (arg.contains("]") && !arg.contains("[")) {
				// camera_create_view(room_x, room_y, width, height, [angle, object, x_speed, y_speed, x_border, y_border])
				var argk = argi;
				while (--argk >= 0) {
					if (args[argk].contains("[")) break;
				}
				if (argk < 0) break; else argi = argk;
			} else break;
		}
		minArgsCache = argi;
		return minArgsCache;
	}
	
	/** Return type based on `->type` or `@return` for post-string */
	public var returnType(get, never):GmlType;
	private function get_returnType():GmlType {
		if (post == __returnType_cache_post) return __returnType_cache_type;
		var str = inline get_returnTypeString();
		var type:GmlType;
		if (str != null) {
			if (templateItems != null) {
				str = GmlTypeTools.patchTemplateItems(str, templateItems);
			}
			type = GmlTypeDef.parse(str);
		} else type = null;
		__returnType_cache_post = post;
		__returnType_cache_type = type;
		return type;
	}
	var __returnType_cache_post:String;
	var __returnType_cache_type:GmlType;
	static var __returnType_rx:RegExp = new RegExp('^\\)(?:$retArrow(\\S+)?)?');
	
	public var returnTypeString(get, set):String;
	private function get_returnTypeString():String {
		var mt = __returnType_rx.exec(post);
		return JsTools.nca(mt, mt[1]);
	}
	private function set_returnTypeString(typeStr:String):String {
		post = NativeString.replaceExt(post, __returnType_rx, function(_) {
			if (typeStr == null) return ")";
			if (typeStr == "") return parRetArrow;
			return parRetArrow + typeStr.replaceExt(JsTools.rx(~/\s+/), "");
		});
		hasReturn = typeStr != null;
		return typeStr;
	}
	
	/**
	 * For fn<K:string, V>() these would be [{name:"K",ct:"string"},{name:"V"}]
	 * For functions without templates this remains null.
	 */
	public var templateItems:Array<GmlTypeTemplateItem> = null;
	
	/** For filling out type params in self.func() calls */
	public var templateSelf:GmlType = null;
	
	public var maxArgs(get, never):Int;
	private function get_maxArgs():Int {
		return rest ? 0x7fffffff : args.length;
	}
	
	/** whether to show "..." in the end of argument list */
	public var rest:Bool;
	
	public function new(name:String, pre:String, post:String, args:Array<String>, rest:Bool) {
		this.name = name;
		this.pre = pre;
		this.post = post;
		this.args = args;
		this.rest = rest;
	}
	
	public function clear():Void {
		post = ")";
		args.resize(0);
		rest = false;
		minArgsCache = null;
	}
	
	public function getAcText() {
		return pre + args.join(", ") + post;
	}
	
	public static function create(name:String, ?args:Array<String>, ?rest:Bool):GmlFuncDoc {
		if (args == null) {
			args = [];
			if (rest == null) rest = false;
		} else if (rest == null) {
			rest = false;
			for (arg in args) {
				if (arg.contains("...")) rest = true;
			}
		}
		return new GmlFuncDoc(name, name + "(", ")", args, rest);
	}
	
	public static function createRest(name:String):GmlFuncDoc {
		return new GmlFuncDoc(name, name + "(", ")", ["..."], true);
	}
	
	/** ("func(a, b)") -> { pre:"func(", args:["a","b"], post:")" } */
	public static inline function parse(s:String, ?out:GmlFuncDoc):GmlFuncDoc {
		return GmlFuncDocParser.parse(s, out);
	}
	
	public inline function fromCode(gml:GmlCode, from:Int = 0, ?till:Int) {
		GmlFuncDocFromCode.proc(this, gml, from, till);
	}
	
	public static var nameTrimRegex = new RegExpCache();
	
	public function trimArgs():Void {
		var ntrx = nameTrimRegex.update(Project.current.properties.argNameRegex);
		if (ntrx == null) return;
		for (i in 0 ... args.length) {
			var mt = ntrx.exec(args[i]);
			if (mt != null && mt[1] != null) args[i] = mt[1];
		}
	}
	
	/** Figures out whether arguments are optional and whether the script returns anything. */
	public inline function procHasReturn(gml:GmlCode, from:Int = 0, ?_till:Int, ?isAuto:Bool, ?autoArgs:Array<String>) {
		GmlFuncDocArgsRet.proc(this, gml, from, _till, isAuto, autoArgs);
	}
}
