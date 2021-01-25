package ace.extern;
import editors.EditCode;
import haxe.Constraints.Function;

/**
 * ...
 * @author YellowAfterlife
 */
class AceHighlight extends AceHighlightImpl {
	public var editor:EditCode;
	public function new() {
		editor = EditCode.currentNew;
	}
}


#if test
class AceHighlightImpl {
	public var rules:AceHighlightRuleset;
	function createKeywordMapper(obj:Dynamic<String>, def:String):Function {return null;}
	function normalizeRules():Void {}
}
#else

@:native("AceHighlightImpl") extern class AceHighlightImpl {
	@:native("$rules") public var rules:AceHighlightRuleset;
	function createKeywordMapper(obj:Dynamic<String>, def:String):Function;
	function normalizeRules():Void;
}
#end