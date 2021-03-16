package yy.zip;
import haxe.io.Bytes;
import haxe.io.Path;

/**
 * ...
 * @author YellowAfterlife
 */
class YyZipFile extends YyZipBase {
	/** last change time */
	public var time:Float;
	private var bytes:Bytes;
	/** whether .bytes are compressed */
	private var compressed:Bool = false;
	private var text:String;
	private var dataURL:String = null;
	public function new(path:String, time:Float) {
		super(path);
		this.time = time;
	}
	private function uncompress() {
		bytes = tools.BufferTools.inflate(bytes);
		compressed = false;
	}
	public function getBytes():Bytes {
		if (bytes == null) {
			bytes = Bytes.ofString(text);
		}
		return bytes;
	}
	public function getText():String {
		if (text == null) {
			if (compressed) uncompress();
			text = bytes.toString();
		}
		return text;
	}
	public function getDataURL():String {
		if (bytes != null) {
			if (compressed) uncompress();
			var kind = switch (Path.extension(path).toLowerCase()) {
				case "png": "image/png";
				default: "application/octet-stream";
			}
			return "data:" + kind + ";base64,"
				+ tools.BufferTools.toBase64(bytes, 0, bytes.length);
		} else return "";
	}
	public function setBytes(b:Bytes, ?isCompressed:Bool) {
		bytes = b;
		compressed = isCompressed;
		text = null;
		dataURL = null;
	}
	public function setText(s:String) {
		text = s;
		bytes = null;
		compressed = false;
		dataURL = null;
	}
}