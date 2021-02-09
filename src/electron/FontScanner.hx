package electron;

import js.lib.Promise;

@:native("libFontScanner") extern class FontScanner {
	static function getAvailableFonts(): Promise<Array<FontDescriptor>>;
	
	static function getAvailableFontsSync(): Array<FontDescriptor>;

}
@:keep class FontScannerFallback {
	public static function getAvailableFonts(): Promise<Array<FontDescriptor>> {
		return new Promise(function(resolve, reject) {
			resolve([]);
		});
	}
	
	public static function getAvailableFontsSync(): Array<FontDescriptor> {
		return [];
	}
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