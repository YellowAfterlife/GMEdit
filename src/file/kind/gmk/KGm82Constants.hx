package file.kind.gmk;

import js.lib.RegExp;
import tools.JsTools;
import editors.EditCode;
using StringTools;
using tools.NativeString;

class KGm82Constants extends KGml {
	public static var inst:KGm82Constants = new KGm82Constants();
	//
	public static function constantsToMacros(code:String, safe:Bool) {
		code = code.replace("\r", "");
		var macros = [];
		static var rxConst = new RegExp("^(\\w+)=(.+)");
		for (line in code.split("\n")) {
			if (line.trimRight() == "") continue;
			var mt = rxConst.exec(line);
			if (mt != null) {
				var value = mt[2];
				if (safe) value = '( $value )';
				macros.push("#macro " + mt[1] + " " + value);
			}
		}
		return macros.join("\n");
	}
	public static function macrosToConstants(code:String, errors:Array<String>) {
		static var rxMacro = new RegExp("^#macro\\s+(\\w+)\\s+(.+)", "");
		code = code.replace("\r", "");
		var out = "";
		for (line in code.split("\n")) {
			if (line.trimRight() == "") continue;
			var mt = rxMacro.exec(line);
			if (mt != null) {
				out += mt[1] + "=" + mt[2] + "\n";
			} else {
				errors.push('"$line" is not a valid macro declaration');
			}
		}
		return out;
	}
	/*
		This one's a bit weird because we want to see
		#macro name value
		when editing but treat it as
		#macro name (value)
		for the linter
	*/
	override function preproc(editor:EditCode, code:String):String {
		code = constantsToMacros(code, false);
		return super.preproc(editor, code);
	}
	override function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		var errors = [];
		code = macrosToConstants(code, errors);
		if (errors.length > 0) {
			editor.setSaveError(errors.join("\n"));
		}
		return code;
	}
	override function index(path:String, content:String, main:String, sync:Bool):Bool {
		var code = constantsToMacros(content, true);
		return super.index(path, code, main, sync);
	}
}