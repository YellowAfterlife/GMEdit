package tools;
import haxe.io.Bytes;
import js.html.Blob;

/**
 * ...
 * @author YellowAfterlife
 */
class BufferTools {
	public static function toBase64(bytes:Bytes, offset:Int, length:Int):String {
		var pos = 0;
		var raw = "";
		while (pos < length) {
			var end = pos + 0x8000;
			if (end > length) end = length;
			var sub = haxe.io.UInt8Array.fromBytes(bytes, offset + pos, end - pos);
			raw += untyped __js__("String.fromCharCode.apply(null, {0})", sub);
			pos = end;
		}
		return Main.window.btoa(raw);
	}
	public static function toObjectURL(bytes:Bytes, path:String, type:String):String {
		try {
			var blob:Blob = new Blob([bytes.getData()], { type: type });
			//
			var nav:Dynamic = js.Browser.navigator;
			if (nav.msSaveBlob != null) {
				nav.msSaveBlob(blob, path);
				return null;
			}
			//
			return js.html.URL.createObjectURL(blob);
		} catch (err:Dynamic) {
			Main.console.error("Failed to make blob", err);
			return "data:" + type + ";base64," + toBase64(bytes, 0, bytes.length);
		}
	}
	public static function inflate(bytes:Bytes):Bytes {
		if (bytes.length > 0) {
			var data = bytes.getData();
			data = untyped Main.window.pako.inflateRaw(data);
			return Bytes.ofData(data);
		} else return Bytes.alloc(0);
	}
	public static function saveAs(bytes:Bytes, path:String, mimetype:String) {
		var url = toObjectURL(bytes, path, mimetype);
		if (url == null) return false;
		var link = Main.document.createAnchorElement();
		link.href = url;
		link.download = path;
		Main.document.body.appendChild(link);
		link.click();
		
		Main.window.setTimeout(function() {
			link.parentElement.removeChild(link);
			try {
				js.html.URL.revokeObjectURL(url);
			} catch (_:Dynamic) {
				//
			}
		});
		return true;
	}
}
