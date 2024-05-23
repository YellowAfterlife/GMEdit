package tools;
import haxe.extern.Rest;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class StringBuilder extends StringBuf {
	public function new() {
		super();
		addFormat = Reflect.makeVarArgs(addFormatImpl);
	}
	public inline function close() { }
	//
	public inline function addString(s:String) this.add(s);
	public inline function addInt(i:Int) this.add(i);
	//
	/** (format, ...args) */
	public var addFormat:String->Rest<Dynamic>->Void = null;
	private static var formatCache:Map<String, Array<String>> = new Map();
	public static var formatMap:Map<String, StringBuilder->Dynamic->Int->Void> = formatInit();
	private static function formatInit() {
		return [
			"%s" => function(b:StringBuilder, s:Dynamic, i:Int) {
				if (s == null || Std.is(s, String)) {
					b.addString(s);
				} else throw 'Expected a string for arg#$i';
			},
			"%d" => function(b:StringBuilder, v:Dynamic, i:Int) {
				if (v == null || Std.is(v, Int)) {
					b.addInt(v);
				} else throw 'Expected an int for arg#$i';
			},
			"%c" => function(b:StringBuilder, v:Dynamic, i:Int) {
				if (v == null || Std.is(v, Int)) {
					b.addInt(v);
				} else throw 'Expected a char for arg#$i';
			},
			"%t" => function(b:StringBuilder, v:Dynamic, i:Int) {
				if (Std.is(v, Int)) {
					for (i in 0 ... v) b.addChar("\t".code);
				} else throw 'Expected a tab count for arg#$i';
			},
		];
	}
	private function addFormatImpl(args:Array<Dynamic>):Dynamic {
		var fmt:String = args[0];
		var data:Array<String> = formatCache[fmt];
		var i:Int, n:Int;
		if (data == null) {
			data = [];
			var start = 0;
			i = 0; n = fmt.length;
			while (i < n) {
				if (fmt.fastCodeAt(i) == "%".code) {
					if (i > start) data.push(fmt.substring(start, i));
					data.push(fmt.substr(i, 2));
					i += 2; start = i;
				} else i += 1;
			}
			if (i > start) data.push(fmt.substring(start, i));
			formatCache[fmt] = data;
		}
		//
		i = -1;
		n = data.length;
		var argi = 0;
		while (++i < n) {
			var arg:String = data[i];
			if (arg.fastCodeAt(0) == "%".code) {
				var fn = formatMap[arg];
				if (fn != null) {
					argi += 1; fn(this, args[argi], argi);
				} else throw '$arg is not a known format.';
			} else addString(arg);
		}
		//
		return null;
	}
	//
}
