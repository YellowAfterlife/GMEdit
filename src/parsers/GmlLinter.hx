package parsers;
import tools.Aliases;
import tools.Dictionary;
import editors.EditCode;
import gml.GmlVersion;
import ace.extern.*;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinter {
	//
	public var errorText:String = null;
	public var errorRow:Int = -1;
	//
	var reader:GmlReaderExt;
	var version:GmlVersion;
	var row:Int;
	
	public function new() {
		//
	}
	//{
	var nextKind:GmlLinterKind = KEOF;
	var nextVal(get, never):String;
	function get_nextVal():String {
		if (__nextVal_cache == null) {
			__nextVal_cache = __nextVal_source.substring(__nextVal_start, __nextVal_end);
		}
		return __nextVal_cache;
	}
	var __nextVal_cache:String = null;
	var __nextVal_source:String = null;
	var __nextVal_start:Int = 0;
	var __nextVal_end:Int = 0;
	function __next_ret(nvk:GmlLinterKind, src:String, nv0:Int, nv1:Int):GmlLinterKind {
		__nextVal_cache = null;
		__nextVal_source = src;
		__nextVal_start = nv0;
		__nextVal_end = nv1;
		nextKind = nvk;
		return nvk;
	}
	function __next_retv(nvk:GmlLinterKind, nv:String):GmlLinterKind {
		__nextVal_cache = nv;
		nextKind = nvk;
		return nvk;
	}
	//
	static var keywords:Dictionary<GmlLinterKind> = (function() {
		var q = new Dictionary<GmlLinterKind>();
		q["var"] = KVar;
		q["globalvar"] = KGlobalVar;
		//
		q["if"] = KIf;
		q["then"] = KThen;
		q["else"] = KElse;
		//
		q["for"] = KFor;
		return q;
	})();
	
	//
	function next():GmlLinterKind {
		var q = reader;
		var nk:GmlLinterKind;
		var nv:String;
		//
		var _src:String;
		inline function start():Void {
			_src = q.source;
		}
		//
		var _inc_amt:Int;
		inline function inc(amt:Int):Void {
			_inc_amt = amt;
			if (q.depth == 0) row += _inc_amt;
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			inline function ret(nk:GmlLinterKind):GmlLinterKind {
				return __next_ret(nk, _src, p, q.pos);
			}
			inline function retv(nk:GmlLinterKind, nv:String):GmlLinterKind {
				return __next_retv(nk, nv);
			}
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); inc(q.skipComment());
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: {
					start();
					inc(q.skipStringAuto(c, version));
					return ret(KString);
				};
				default: {
					if (c.isIdent0()) {
						q.skipIdent1();
						nv = q.substring(p, q.pos);
						return retv(keywords.defget(nv, KIdent), nv);
					}
				};
			}
		}
		start();
		return __next_retv(KEOF, "");
	}
	//}
	
	public function readStat():FoundError {
		
		return false;
	}
	
	public function run(source:GmlCode, ?version:GmlVersion):FoundError {
		this.version = version;
		var q = reader = new GmlReaderExt(source.trimRight());
		row = 1;
		while (q.loop) if (readStat()) return true;
		return false;
	}
	
	public static function runFor(editor:EditCode):Bool {
		var q = new GmlLinter();
		var session = editor.session;
		if (session.gmlErrorMarkers != null) {
			for (mk in session.gmlErrorMarkers) session.removeMarker(mk);
			session.gmlErrorMarkers.clear();
			session.clearAnnotations();
		}
		if (q.run(session.getValue())) {
			if (session.gmlErrorMarkers == null) session.gmlErrorMarkers = [];
			var row = q.errorRow;
			var rowl = session.getLine(row).length;
			var range = new AceRange(0, row, rowl, row);
			session.gmlErrorMarkers.push(session.addMarker(range, "ace_error-line", "fullLine"));
			session.setAnnotations([{
				row: row, column: rowl, type: "error", text: q.errorText
			}]);
			return true;
		} else return false;
	}
}
@:build(tools.AutoEnum.build())
enum abstract GmlLinterKind(Int) {
	public function getName():String {
		return "<unknown>";
	}
	var KEOF;
	var KString;
	var KIdent;
	//
	var KVar;
	var KGlobalVar;
	//{
	var KIf;
	var KThen;
	var KElse;
	//
	var KFor;
	var KDo;
	var KWhile;
	var KUntil;
	var KRepeat;
	var KBreak;
	var KContinue;
	//}
}
