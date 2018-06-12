package tools;

/**
 * ...
 * @author YellowAfterlife
 */
class Base64 {
	public static function s2b(s:String):Array<Int> {
		var a = new Array();
		// utf16-decode and utf8-encode
		var i = 0;
		while( i < s.length ) {
			var c : Int = StringTools.fastCodeAt(s,i++);
			// surrogate pair
			if( 0xD800 <= c && c <= 0xDBFF )
			    c = (c - 0xD7C0 << 10) | (StringTools.fastCodeAt(s,i++) & 0x3FF);
			if( c <= 0x7F ) {
				a.push(c);
			} else if( c <= 0x7FF ) {
				a.push( 0xC0 | (c >> 6) );
				a.push( 0x80 | (c & 63) );
			} else if( c <= 0xFFFF ) {
				a.push( 0xE0 | (c >> 12) );
				a.push( 0x80 | ((c >> 6) & 63) );
				a.push( 0x80 | (c & 63) );
			} else {
				a.push( 0xF0 | (c >> 18) );
				a.push( 0x80 | ((c >> 12) & 63) );
				a.push( 0x80 | ((c >> 6) & 63) );
				a.push( 0x80 | (c & 63) );
			}
		}
		return a;
	}
	public static function b2s(b:Array<Int>):String {
		var s = "";
		var fcc = String.fromCharCode;
		var i = 0;
		var max = b.length;
		// utf8-decode and utf16-encode
		while( i < max ) {
			var c = b[i++];
			if( c < 0x80 ) {
				if( c == 0 ) break;
				s += fcc(c);
			} else if( c < 0xE0 )
				s += fcc( ((c & 0x3F) << 6) | (b[i++] & 0x7F) );
			else if( c < 0xF0 ) {
				var c2 = b[i++];
				s += fcc( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (b[i++] & 0x7F) );
			} else {
				var c2 = b[i++];
				var c3 = b[i++];
				var u = ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 & 0x7F) << 6) | (b[i++] & 0x7F);
				// surrogate pair
				s += fcc( (u >> 10) + 0xD7C0 );
				s += fcc( (u & 0x3FF) | 0xDC00 );
			}
		}
		return s;
	}
	static var chars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	public static function encode(s:String):String {
		var c = chars;
		var b = s2b(s), n = b.length, r = "", i:Int;
		var i = 0;
		while (i < n) {
			r += c.charAt(b[i] >> 2);
			r += c.charAt(((b[i] & 3) << 4) | (b[i + 1] >> 4));
			r += c.charAt(((b[i + 1] & 15) << 2) | (b[i + 2] >> 6));
			r += c.charAt(b[i + 2] & 63);
			i += 3;
		}
		if ((n % 3) == 2) {
			r = r.substring(0, r.length - 1) + "=";
		} else if ((n % 3) == 1) {
			r = r.substring(0, r.length - 2) + "==";
		}
		return r;
	}
	public static function decode(s:String):String {
		var c = chars;
		var r = [], n = s.length;
		var i = 0;
		while (i < n) {
			var e1 = c.indexOf(s.charAt(i++));
			var e2 = c.indexOf(s.charAt(i++));
			var e3 = c.indexOf(s.charAt(i++));
			var e4 = c.indexOf(s.charAt(i++));
			r.push((e1 << 2) | (e2 >> 4));
			r.push(((e2 & 15) << 4) | (e3 >> 2));
			r.push(((e3 & 3) << 6) | (e4 & 63));
		}
		if (s.charCodeAt(n - 1) == "=".code) r.pop();
		if (s.charCodeAt(n - 2) == "=".code) r.pop();
		return b2s(r);
	}
}
