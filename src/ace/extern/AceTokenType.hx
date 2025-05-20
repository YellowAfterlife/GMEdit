package ace.extern;

import js.lib.RegExp;

/**
**/
abstract AceTokenType(String) from String to String {
	static var rxKeyword = new RegExp("\\bkeyword\\b");
	public inline function isKeyword() {
		return rxKeyword.test(this);
	}
	
	static var rxImportPath = new RegExp("\\bimportpath\\b");
	public inline function isImportPath() {
		return rxImportPath.test(this);
	}
}
