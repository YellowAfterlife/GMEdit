package gml;

/**
 * ...
 * @author YellowAfterlife
 */
@:build(tools.AutoEnum.build("int"))
@:enum abstract GmlVersion(Int) to Int {
	/** not set yet */
	var none = 0;
	
	/** GMS1 */
	var v1 = 1;
	
	/** GMS2 */
	var v2 = 2;
	
	/** GMLive variant (has template strings and a few extra keywords) */
	var live = -1;
	
	public inline function hasStringEscapeCharacters() {
		return this == v2;
	}
	public inline function hasLiteralStrings() {
		return this == v2;
	}
	public inline function hasSingleQuoteStrings() {
		return this != v2;
	}
	
	/** Whether GMLive specific string interpolation is supported */
	public inline function hasTemplateStrings() {
		#if lwedit
		return true;
		#else
		return this == live;
		#end
	}
	
	/** Whether the ternary operator is supported */
	public inline function hasTernaryOperator() {
		return this != v1;
	}
	
	/** Whether GMS2 style `/// @meta` docs are used */
	public inline function hasJSDoc() {
		return this == v2;
	}
	
	/** Whether it's allowed to do `#define script(arg1, arg2)` */
	public inline function hasScriptArgs() {
		#if lwedit
		return true;
		#else
		return this == live;
		#end
	}
	
	/** Whether a #define/#event/etc. resets line counter */
	public inline function resetOnDefine() {
		#if lwedit
		return false;
		#else
		return this != live;
		#end
	}
	
	public function getName() {
		return null;
	}
}
