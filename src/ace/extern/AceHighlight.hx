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
@:native("AceHighlightImpl") extern class AceHighlightImpl {
	@:native("$rules") public var rules:AceHighlightRuleset;
	function createKeywordMapper(obj:Dynamic<String>, def:String):Function;
	function normalizeRules():Void;
}
