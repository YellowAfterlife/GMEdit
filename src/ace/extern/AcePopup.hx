package ace.extern;
import haxe.extern.EitherType;
import js.html.Element;

/**
 * ...
 * @author YellowAfterlife
 */
extern class AcePopup {
	public static inline function create(ctr:Element):AcePopup {
		var popup = AceWrap.require("ace/autocomplete/popup").AcePopup;
		return js.Syntax.construct(popup, ctr);
	}
	function getRow():Int;
	function getData(row:Int):Dynamic;
	function setData(arr:Dynamic):Void;
	var container:Element;
}