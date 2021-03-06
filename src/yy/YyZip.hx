package yy;
import gml.GmlVersion;
import gml.Project;
import gmx.SfGmx;
import haxe.Json;
import haxe.ds.List;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import js.Browser;
import js.lib.Error;
import js.lib.RegExp;
import js.html.FormElement;
import js.html.InputElement;
import js.html.Blob;
import tools.Dictionary;
using tools.NativeString;
using haxe.io.Path;
using tools.PathTools;

/**
 * Allows manipulation of YYZ files and virtual projects in general.
 * @author YellowAfterlife
 */
class YyZip extends Project {
	private var yyzFileList:Array<YyZipFile> = [];
	private var yyzFileMap:Dictionary<YyZipFile> = new Dictionary();
	private static var rxBackslash = new RegExp("\\\\", "g");
	//
	public function new(path:String, main:String, entries:Array<YyZipFile>) {
		super(main);
		isVirtual = true;
		yyzFileList = entries;
		for (entry in entries) {
			yyzFileMap.set(entry.path.replaceExt(rxBackslash, "/"), entry);
		}
	}
	private static function locateMain(entries:Array<YyZipFile>) {
		var main = null;
		var mainDepth = 0;
		for (entry in entries) {
			var path = entry.path;
			var pair = path.ptDetectProject();
			if (pair.version != GmlVersion.none) {
				var depth = path.ptDepth();
				if (main == null || depth < mainDepth) {
					main = path;
					mainDepth = depth;
				}
			}
		}
		return main;
	}
	/** Opens a YYZ/ZIP file */
	public static function open(path:String, bytes:Bytes) {
		var fileName = null;
		try {
			var entryList = haxe.zip.Reader.readZip(new haxe.io.BytesInput(bytes));
			var entries:Array<YyZipFile> = [];
			for (entry in entryList) {
				var file = new YyZipFile(entry.fileName, entry.fileTime.getTime());
				file.setBytes(entry.data, entry.compressed);
				entries.push(file);
			}
			var main = locateMain(entries);
			if (main == null) {
				Main.window.alert("The archive contains no project files.");
				return false;
			}
			fileName = null;
			Project.current = new YyZip(path, main, entries);
			return true;
		} catch (e:Dynamic) {
			Main.console.log('Error processing YYZ ($fileName)', e);
			return false;
		}
	}
	public function toZip():Bytes {
		var output = new haxe.io.BytesOutput();
		var writer = new haxe.zip.Writer(output);
		var entries = new List();
		var now = Date.now();
		for (file in yyzFileList) {
			var bytes = file.getBytes();
			entries.push({
				fileName: file.path,
				fileSize: bytes.length,
				fileTime: now,
				compressed: false,
				dataSize: bytes.length,
				data: bytes,
				crc32: haxe.crypto.Crc32.make(bytes)
			});
		}
		//
		writer.write(entries);
		return output.getBytes().sub(0, output.length);
	}
	//
	private static var directoryDialog_form:FormElement = null;
	private static var directoryDialog_input:InputElement;
	private static function directoryDialog_init() {
		var form = Main.document.createFormElement();
		var input = Main.document.createInputElement();
		input.setAttribute("webkitdirectory", "");
		input.setAttribute("mozdirectory", "");
		input.type = "file";
		input.addEventListener("change", directoryDialog_check);
		form.appendChild(input);
		Main.document.body.appendChild(form);
		directoryDialog_form = form;
		directoryDialog_input = input;
	}
	private static function directoryDialog_check(_) {
		var main = null;
		var entries:Array<YyZipFile> = [];
		var left = 1;
		function next() {
			if (--left > 0) return;
			var main = locateMain(entries);
			if (main == null) {
				Main.window.alert("Couldn't find any project files in directory");
				return;
			}
			// unpack entries from directory, where possible:
			do {
				var mt = new RegExp("^.+?[\\/]").exec(main);
				if (mt == null) break;
				var dir = mt[0];
				// ensure that all entries start with this path:
				var i = entries.length;
				while (--i >= 0) if (!entries[i].path.startsWith(dir)) break;
				if (i >= 0) break;
				// crop it off:
				var start = dir.length;
				i = entries.length;
				while (--i >= 0) entries[i].path = entries[i].path.substring(start);
				main = main.substring(start);
			} while (false);
			//
			Project.current = new YyZip(main, main, entries);
		}
		//
		var files = directoryDialog_input.files;
		if (files.length == 0) return;
		var status = "Loading " + files.length + " file";
		if (files.length != 1) status += "s";
		tools.HtmlTools.setInnerText(Project.nameNode, status + "...");
		//
		for (file in files) {
			var rel = untyped file.webkitRelativePath;
			if (main == null) {
				var ext = Path.extension(rel);
				if (ext.toLowerCase() != "yyp") {
					ext = Path.extension(Path.withoutExtension(rel)).toLowerCase();
					if (ext.toLowerCase() != "project") {
						var lqr = Path.withoutDirectory(rel).toLowerCase();
						if (lqr == "main.txt" || lqr == "main.cfg") main = rel;
					} else main = rel;
				} else main = rel;
			}
			//
			var reader = new js.html.FileReader();
			reader.onloadend = function(_) {
				var abuf:js.lib.ArrayBuffer = reader.result;
				var bytes = haxe.io.Bytes.ofData(abuf);
				var zipFile = new YyZipFile(rel, file.lastModified);
				zipFile.setBytes(bytes);
				entries.push(zipFile);
				next();
			};
			left += 1;
			reader.readAsArrayBuffer(file);
		}
		next();
	}
	public static function directoryDialog() {
		if (directoryDialog_form == null) directoryDialog_init();
		directoryDialog_form.reset();
		directoryDialog_input.click();
	}
	//
	static inline function fixSlashes(s:String) {
		return s.replaceExt(rxBackslash, "/");
	}
	override public function existsSync(path:String):Bool {
		return yyzFileMap[fixSlashes(path)] != null;
	}
	override public function mtimeSync(path:String):Null<Float> {
		var file = yyzFileMap[fixSlashes(path)];
		return file != null ? file.time : null;
	}
	override public function unlinkSync(path:String):Void {
		path = fixSlashes(path);
		var file = yyzFileMap[path];
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
		var t = Date.now().getTime();
		if (file == null) {
			file = new YyZipFile(fwpath, t);
			file.setText(text);
			yyzFileMap.set(fwpath, file);
			yyzFileList.push(file);
		} else {
			file.setText(text);
			file.time = t;
		}
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
	override public function readYyFileSync<T>(path:String):T {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return YyJson.parse(file.getText());
		} else throw new Error("File not found: " + path);
	}
	// no need to override writeJson/Yy - base version already uses writeTextFileSync
	
	override public function readGmxFile(path:String, fn:Error->SfGmx->Void):Void {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			fn(null, SfGmx.parse(file.getText()));
		} else fn(new Error("File not found: " + path), null);
	}
	override public function readGmxFileSync(path:String):SfGmx {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return SfGmx.parse(file.getText());
		} else throw new Error("File not found: " + path);
	}
	override public function getImageURL(path:String):String {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return file.getDataURL();
		} else return null;
	}
	override public function renameSync(prev:String, next:String) {
		prev = fixSlashes(prev);
		next = fixSlashes(next);
		var file = yyzFileMap[prev];
		if (file != null) {
			file.path = next;
			yyzFileMap.remove(prev);
			yyzFileMap.set(next, file);
		} else {
			var rx = new RegExp("^" + NativeString.escapeRx(prev) + "([/\\\\].+)$");
			for (file in yyzFileList) {
				var mt = rx.exec(file.path);
				if (mt == null) continue;
				yyzFileMap.remove(file.path);
				file.path = next + mt[1];
				yyzFileMap.set(file.path, file);
			}
		}
	}
	override public function readdirSync(path:String):Array<ProjectDirInfo> {
		var out = [];
		var foundDirs = new Dictionary();
		var full = fixSlashes(path);
		var prefix = full != "" ? full + "/" : ""; // -> "a/b/"
		var prefixLen = prefix.length;
		for (file in yyzFileList) {
			var filePath = file.path; // -> "a/b/f.x"|"a/b/c/f.y"
			if (filePath.startsWith(prefix)) {
				if (Path.directory(filePath) == full) {
					var cut = Path.withoutDirectory(filePath);
					if (cut != "") out.push({
						fileName: cut,
						relPath: path + "/" + cut,
						fullPath: filePath,
						isDirectory: false
					});
				} else {
					var cut = filePath.substring(prefixLen); // "a/b/f.x" -> "f.x"
					// "c/f.y" -> "c":
					var ofs = cut.indexOf("/");
					if (ofs >= 0) {
						var dir = cut.substring(0, ofs);
						if (!foundDirs.exists(dir)) {
							foundDirs.set(dir, true);
							out.push({
								fileName: dir,
								relPath: path + "/" + dir,
								fullPath: path + "/" + dir,
								isDirectory: true
							});
						}
					}
				}
			}
		}
		return out;
	}
	override public function mkdirSync(path:String, ?options:{?recursive: Bool, ?mode: Int}) {
		// (directories are implicit in ZIP)
	}
	override public function rmdirSync(path:String) {
		//
	}
	static function getMimeType(ext:String) {
		// todo: get a full list from somewhere if this ever matters
		return switch (ext) {
			case "bmp": "image/bmp";
			case "png": "image/png";
			case "jpg", "jpeg": "image/jpeg";
			case "gif": "image/gif";
			case "svg": "image/svg+xml";
			case "txt", "conf", "log": "text/plain";
			case "mp3", "m3a": "audio/mpeg";
			case "exe", "dll", "com", "bat", "msi": "application/x-msdownload";
			case "7z": "application/x-7z-compressed";
			case "zip": "application/zip";
			case "xml": "application/xml";
			case "csv": "text/csv";
			default: "application/octet-stream";
		}
	}
	override public function openExternal(path:String) {
		
	}
}
class YyZipFile {
	public var path:String;
	/** last change time */
	public var time:Float;
	private var bytes:Bytes;
	/** whether .bytes are compressed */
	private var compressed:Bool = false;
	private var text:String;
	private var dataURL:String = null;
	public function new(path:String, time:Float) {
		this.path = path;
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
