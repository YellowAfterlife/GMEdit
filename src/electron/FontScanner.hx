package electron;

import js.lib.Promise;

@:jsRequire("font-scanner")
extern class FontScanner {
	static function getAvailableFonts(): Promise<Array<FontDescriptor>>;
	
	static function getAvailableFontsSync(): Array<FontDescriptor>;

}

typedef FontDescriptor = {
	path: String,
	style: String,
	width: Float,
	family: String,
	weight: Int,
	italic: Bool,
	monospace: Bool,
	postscriptName: String
}