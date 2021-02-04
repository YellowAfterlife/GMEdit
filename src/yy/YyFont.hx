package yy;

import tools.Dictionary;

/**Represents a 2.3 font*/
@:forward
abstract YyFont(YyFontImpl) from YyFontImpl to YyFontImpl {
	//

	public static function GenerateDefault(parent: YyResourceRef, name: String):YyFont {
		return {
			"hinting": 0,
			"glyphOperations": 0,
			"interpreter": 0,
			"pointRounding": 0,
			"fontName": "Arial",
			"styleName": "Regular",
			"size": 12.0,
			"bold": false,
			"italic": false,
			"charset": 0,
			"AntiAlias": 1,
			"first": 0,
			"last": 0,
			"sampleText": "abcdefg ABCDEFG\n0123456789 .,<>\"'&!?\nthe quick brown fox jumps over the lazy dinosaur\nTHE QUICK BROWN FOX JUMPS OVER THE LAZY DINOSAUR\nDefault character: ▯ (9647)",
			"includeTTF": false,
			"TTFName": "",
			"textureGroupId": {
			  "name": "Default",
			  "path": "texturegroups/Default",
			},
			"ascenderOffset": 0,
			"glyphs": {},
			"kerningPairs": [],
			"ranges": [
			  {"lower":32,"upper":127,},
			  {"lower":9647,"upper":9647,},
			],
			"regenerateBitmap": false,
			"canGenerateBitmap": true,
			"maintainGms1Font": false,
			"parent": parent,
			"resourceVersion": "1.0",
			"name": name,
			"tags": [],
			"resourceType": "GMFont",
		}
	}
}

typedef YyFontImpl = {
	>YyResource,
	hinting:Int,
	/**Bitmask holding various operations*/
	glyphOperations:Int,
	interpreter:Int,
	pointRounding:Int,
	fontName:String,
	styleName:String,
	size:Float,
	bold:Bool,
	italic:Bool,
	charset:Int,
	AntiAlias:Int,
	first:Int,
	last:Int,
	sampleText:String,
	includeTTF:Bool,
	TTFName:String,
	textureGroupId:{
		name:String,
		path:String
	},
	ascenderOffset:Int,
	glyphs:{},
	kerningPairs:Array<Any>,
	ranges:Array<YyFontRange>,
	regenerateBitmap:Bool,
	canGenerateBitmap:Bool,
	maintainGms1Font:Bool,
};

typedef YyFontRange = {
	lower: Int,
	upper: Int
}