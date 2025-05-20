package ace.extern;
import ace.extern.AceTokenType;
import js.lib.RegExp;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AceToken(AceTokenImpl) from AceTokenImpl to AceTokenImpl {
	public inline function new(type:String, value:String) {
		this = { type: type, value: value };
	}
	
	/** shortcut for value.length */
	public var length(get, never):Int;
	private inline function get_length():Int {
		return this.value.length;
	}
	
	/** type or `null` if `this == null` */
	public var ncType(get, never):AceTokenType;
	private inline function get_ncType():AceTokenType {
		return JsTools.nca(this, this.type);
	}
	
	/** value or `null` if `this == null` */
	public var ncValue(get, never):String;
	private inline function get_ncValue():String {
		return JsTools.nca(this, this.value);
	}
	
	/** Returns whether `value` is an identifier (/^\w+$/) */
	public inline function isIdent():Bool return __isIdent.test(this.value);
	private static var __isIdent:RegExp = JsTools.rx(~/^\w+$/);
	
	public inline function isKeyword() return this.type.isKeyword();
}
typedef AceTokenImpl = { type:AceTokenType, value:String, ?index:Int, ?start:Int };
