package yy;

import js.html.svg.Length;
import tools.NativeArray;
import tools.NativeString;
using Lambda;

/**Represents a 2.3 font*/
@:forward
abstract YyFont(YyFontImpl) from YyFontImpl to YyFontImpl {
	//

	/**
	 * Create a new YyFont with the default values found in 2.3
	 */
	public static function generateDefault(parent: YyResourceRef, name: String):YyFont {
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

	public var characterCount(get,never): Int;

	/**Returns the total number of characters in the font*/
	private function get_characterCount(): Int {
		var sum = 0;
		for (range in this.ranges) {
			sum += range.upper - range.lower + 1;
		}
		return sum;
	}


	/**
	 * Add characters to the font ranges of the font, creating and merging ranges as necessary
	 * @param letters letters to add to the range
	 */
	public function addCharacters(letters:String) {
		var letterCodes = new Array<Int>();
		var letterStringCodes: Array<String> = NativeArray.from(letters);
		for (letterStringCode in letterStringCodes) {
			letterCodes.push(NativeString.codePointAt(letterStringCode, 0));
		}

		// Backwards sort, we want to pop smaller values first
		letterCodes.sort((a, b) -> b-a);

		
		var last:YyFontRange = null;
		var next:YyFontRange = this.ranges.length == 0 ? null : this.ranges[0];
		var index = 0;

		while (letterCodes.length > 0) {
			var letterCode = letterCodes.pop();

			// Always stay lower than next.lower
			while (next != null && letterCode > next.lower) {
				last = next;
				index++;
				next = this.ranges[index];
			}

			// We're inside last, skip
			if (last != null && last.upper >= letterCode) {
				continue;
			}

			// Add 1 to last.upper if we're on the edge
			if (last != null && last.upper+1 == letterCode) {
				last.upper = letterCode;

				// Bridge next and last if we're on the edge
				if (next != null && last.upper+1 == next.lower) {
					next.lower = last.lower;
					this.ranges.remove(last);
					last = next;
					next = this.ranges[index]; // Since we removed last the index is now at the proper next spot
				}
				continue;
			}

			// Add 1 to next lower if we're on the edge
			if (next != null && next.lower-1 == letterCode) {
				next.lower = letterCode;
				continue;
			}

			// No adding, this means we're creating a new range for us.
			last = {lower:letterCode, upper: letterCode};
			this.ranges.insert(index, last);
			index++;
		}
	}

	/**
	 * Returns all characters in the font as a string
	 */
	public function getAllCharacters(): String {
		var str = "";
		for (range in this.ranges) {
			for (i in range.lower...range.upper+1) {
				str+= NativeString.fromCodePoint(i);
			}
		}

		return str;
	}

	/**
	 * Adds a range to the ranges, sorts and merging as necessary
	 */
	 public function addRange(range: YyFontRange) {
		if (this.ranges.length == 0) {
			this.ranges.push(range);
			return;
		}
		
		var toRemove = new Array<YyFontRange>();
		// Absorb everything it touches
		for (otherRange in this.ranges) {
			if ( range.lower - 1 <= otherRange.upper && range.upper + 1 >= otherRange.lower ) {
				range.lower = cast Math.min(otherRange.lower, range.lower);
				range.upper = cast Math.max(otherRange.upper, range.upper);
				toRemove.push(otherRange);
			}
		}

		for (otherRange in toRemove) {
			this.ranges.remove(otherRange);
		}

		for (i in 0...this.ranges.length) {
			var otherRange = this.ranges[i];
			if (otherRange.lower > range.lower) {
				this.ranges.insert(i, range);
				return;
			}
		}

		// Nothing found, add to the end
		this.ranges.push(range);
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
