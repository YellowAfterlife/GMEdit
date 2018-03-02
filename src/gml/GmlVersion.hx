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
	public inline function hasTemplateStrings() {
		return this == live;
	}
	public inline function hasTernaryOperator() {
		return this != v1;
	}
	public inline function hasJSDoc() {
		return this == v2;
	}
	
	public function getName() {
		return null;
	}
}
