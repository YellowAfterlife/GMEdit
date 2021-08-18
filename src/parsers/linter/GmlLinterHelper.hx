package parsers.linter;

import tools.Aliases.FoundError;
import editors.EditCode;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
//@:build(tools.macros.GmlLinterMacros.__generateForward())
class GmlLinterHelper {
	var linter:GmlLinter;
	public function new(linter:GmlLinter) {
		this.linter = linter;
	}
	
	inline function setError(text:String):Void linter.setError(text);
	inline function addWarning(text:String):Void linter.addWarning(text);
	inline function readExpect(what:String):FoundError return linter.readExpect(what);
	
	var reader(get, never):GmlReaderExt;
	inline function get_reader() return linter.reader;
	
	var editor(get, never):EditCode;
	inline function get_editor() return linter.editor;
	
	var context(get, set):String;
	inline function get_context() return linter.context;
	inline function set_context(c) return linter.context = c;
	
	inline function peek() return linter.peek();
	inline function skip() return linter.skip();
	inline function next() return linter.next();
	inline function skipIf(cond:Bool):Bool return linter.skipIf(cond);
	
	var nextVal(get, never):String;
	inline function get_nextVal() return linter.nextVal;
	
	var setLocalVars(get, never):Bool;
	inline function get_setLocalVars() return linter.setLocalVars;
	var setLocalTypes(get, never):Bool;
	inline function get_setLocalTypes() return linter.setLocalTypes;
	
	inline function readCheckSkip(kind:GmlLinterKind, expect:String):FoundError {
		return linter.readCheckSkip(kind, expect);
	}
	inline function readStat(oldDepth:Int, flags:GmlLinterReadFlags = GmlLinterReadFlags.None, ?_nk:GmlLinterKind):FoundError {
		return linter.readStat(oldDepth, flags, _nk);
	}
	
	// todo: generate these with a macro instead (maybe taking an extern class?)
	/*public static macro function __generateForward():Array<Field> {
		var fields = Context.getBuildFields();
		var lc:ClassType = null;
		for (t in Context.getModule("parsers.linter.GmlLinter")) {
			switch (t) {
				case TInst(_.get() => c = { name: "GmlLinter" }, _): lc = c; break;
				default: 
			}
		}
		var lcp = Context.currentPos();
		if (lc == null) {
			Context.warning("No GmlLinter in GmlLinter?", lcp);
			return fields;
		}
		inline function cct(t:TypeDefinition) {
			for (fd in t.fields) fields.push(fd);
		}
		for (fd in lc.fields.get()) {
			var fdName = fd.name;
			var fdType = fd.type;
			var fdCt = haxe.macro.TypeTools.toComplexType(fdType);
			if (fdName.startsWith("get_") || fdName.startsWith("set_")) continue;
			switch (fd.kind) {
				case FVar(r, AccNo | AccNever):
					var getter = "get_" + fdName;
					cct(macro class {
						var $fdName(get, never):$fdCt;
						inline function $getter():$fdCt {
							return linter.$fdName;
						}
					});
				case FVar(r, w):
					var getter = "get_" + fdName;
					var setter = "set_" + fdName;
					cct(macro class {
						var $fdName(get, set):$fdCt;
						inline function $getter():$fdCt {
							return linter.$fdName;
						}
						inline function $setter(val:$fdCt):$fdCt {
							linter.$fdName = val;
							return val;
						}
					});
				case FMethod(mk):
					switch (fdType) {
						case TLazy(f): fdType = f(); // <- trouble
						default:
					}
					trace(fdName, fdType);
			}
		}
		//for (fd in fields) trace(fd);
		return fields;
	}*/
}