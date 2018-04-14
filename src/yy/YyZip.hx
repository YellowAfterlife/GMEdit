package yy;
import gml.Project;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import js.Error;
import js.RegExp;
import tools.Dictionary;
using tools.NativeString;

/**
 * Allows manipulation of YYZ files
 * @author YellowAfterlife
 */
class YyZip extends Project {
	private var yyzFileList:Array<YyZipFile> = [];
	private var yyzFileMap:Dictionary<YyZipFile> = new Dictionary();
	private static var rxBackslash = new RegExp("\\\\", "g");
	//
	public function new(path:String, entries:Array<YyZipFile>) {
		super("yyz://" + path);
		isVirtual = true;
		yyzFileList = entries;
		for (entry in entries) {
			yyzFileMap.set(entry.path.replaceExt(rxBackslash, "/"), entry);
		}
	}
	public static function open(path:String, bytes:Bytes) {
		var fileName = null;
		try {
			var entryList = haxe.zip.Reader.readZip(new haxe.io.BytesInput(bytes));
			var entries:Array<YyZipFile> = [];
			var main = path;
			for (entry in entryList) {
				fileName = entry.fileName;
				if (Path.directory(fileName) == ""
				&& Path.extension(fileName).toLowerCase() == "yyp") {
					main = fileName;
				}
				//
				var bytes:Bytes;
				if (entry.compressed && entry.data.length > 0) {
					var data = entry.data.getData();
					data = untyped window.pako.inflateRaw(data);
					bytes = Bytes.ofData(data);
				} else bytes = entry.data;
				entries.push(new YyZipFile(fileName, bytes));
			}
			fileName = null;
			Project.current = new YyZip(main, entries);
			return true;
		} catch (e:Dynamic) {
			Main.console.log('Error processing YYZ ($fileName)', e);
			return false;
		}
	}
	//
	inline function fixSlashes(s:String) {
		return s.replaceExt(rxBackslash, "/");
	}
	override public function existsSync(path:String):Bool {
		return yyzFileMap[fixSlashes(path)] != null;
	}
	override public function unlinkSync(path:String):Void {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			yyzFileMap.remove(path);
			yyzFileList.remove(file);
		}
	}
	override public function readTextFile(path:String, fn:Error->String->Void):Void {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			fn(null, file.getText());
		} else fn(new Error("File not found: " + path), null);
	}
	override public function readTextFileSync(path:String):String {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return file.getText();
		} else throw new Error("File not found: " + path);
	}
	override public function writeTextFileSync(path:String, text:String) {
		var fwpath = fixSlashes(path);
		var file = yyzFileMap[fwpath];
		if (file == null) {
			file = new YyZipFile(fwpath, null, text);
		} else file.setText(text);
	}
	override public function readJsonFile<T:{}>(path:String, fn:Error->T->Void):Void {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			fn(null, Json.parse(file.getText()));
		} else fn(new Error("File not found: " + path), null);
	}
	override public function readJsonFileSync<T>(path:String):T {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return Json.parse(file.getText());
		} else throw new Error("File not found: " + path);
	}
	override public function getImageURL(path:String):String {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return file.getDataURL();
		} else return null;
	}
}
private class YyZipFile {
	public var path:String;
	private var bytes:Bytes;
	private var text:String;
	private var dataURL:String = null;
	public function new(path:String, bytes:Bytes, ?text:String) {
		this.path = path;
		this.bytes = bytes;
		this.text = text;
	}
	public function getBytes():Bytes {
		if (bytes == null) {
			bytes = Bytes.ofString(text);
		}
		return bytes;
	}
	public function getText():String {
		if (text == null) {
			text = bytes.toString();
		}
		return text;
	}
	static function base64of(bytes:Bytes, offset:Int, length:Int) {
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
	public function getDataURL():String {
		if (bytes != null) {
			var kind = switch (Path.extension(path).toLowerCase()) {
				case "png": "image/png";
				default: "application/octet-stream";
			}
			return "data:" + kind + ";base64,"
				+ base64of(bytes, 0, bytes.length);
		} else return "";
	}
	public function setBytes(b:Bytes) {
		bytes = b;
		text = null;
		dataURL = null;
	}
	public function setText(s:String) {
		text = s;
		bytes = null;
		dataURL = null;
	}
}
