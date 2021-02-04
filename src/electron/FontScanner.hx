package electron;

import js.lib.Promise;

#if !test
@:jsRequire("font-scanner")
extern class FontScanner {
	static function getAvailableFonts(): Promise<Array<FontDescriptor>>;
	
	static function getAvailableFontsSync(): Array<FontDescriptor>;

}
#else
class FontScanner {
	public static function getAvailableFonts(): Promise<Array<FontDescriptor>> { return null; }
	
	public static function getAvailableFontsSync(): Array<FontDescriptor> {return null;}
}

#end

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