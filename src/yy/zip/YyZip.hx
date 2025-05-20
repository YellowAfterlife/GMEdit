package yy.zip;
import electron.extern.NodeBuffer;
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
import js.html.Console;
import tools.Dictionary;
import tools.JsTools;
import yy.zip.YyZipTools;
using tools.NativeString;
using haxe.io.Path;
using tools.PathTools;
using tools.NativeArray;

/**
 * Allows manipulation of YYZ files and virtual projects in general.
 * @author YellowAfterlife
 */
class YyZip extends Project {
	/** Full path */
	public var yyzPath:String;
	
	private var yyzFileList:Array<YyZipFile> = [];
	private var yyzFileMap:Dictionary<YyZipFile> = new Dictionary();
	private var yyzDirMap:Dictionary<YyZipDir> = new Dictionary();
	private function yyzGetParentDir(path:String):YyZipDir {
		var parts = path.split("/");
		var fname = parts.pop();
		var prefixes = [for (i => _ in parts) parts.slice(0, i + 1).join("/")];
		var dir:YyZipDir = yyzDirMap[""];
		for (i => dirPath in prefixes) {
			var parent = dir;
			dir = yyzDirMap[dirPath];
			if (dir != null) continue;
			dir = new YyZipDir(dirPath);
			yyzDirMap[dirPath] = dir;
			parent.entries.push(dir);
		}
		return dir;
	}
	private function yyzAddFile(file:YyZipFile):Void {
		yyzFileList.push(file);
		yyzFileMap.set(file.path.replaceExt(rxBackslash, "/"), file);
		yyzGetParentDir(file.path).entries.push(file);
	}
	private static var rxBackslash:RegExp = JsTools.rx(~/\\/g);
	//
	public function new(path:String, main:String, entries:Array<YyZipFile>) {
		yyzPath = path;
		super(main);
		isVirtual = true;
		yyzDirMap[""] = new YyZipDir("");
		for (entry in entries) {
			yyzAddFile(entry);
		}
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
			var main = YyZipTools.locateMain(entries);
			if (main == null) {
				Main.window.alert("The archive contains no project files.");
				return false;
			}
			fileName = null;
			Project.current = new YyZip(path, main, entries);
			return true;
		} catch (e:Dynamic) {
			Console.log('Error processing YYZ ($fileName)', e);
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
	static inline function fixSlashes(s:String) {
		return s.replaceExt(rxBackslash, "/");
	}
	override public function existsSync(path:String):Bool {
		path = fixSlashes(path);
		return yyzFileMap.exists(path) || yyzDirMap.exists(path);
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
			var dir = yyzDirMap[file.dir];
			if (dir != null) {
				dir.entries.remove(file);
				// no need to unlink empty directories since we don't save them to ZIP anyway
			}
			return;
		}
		var dir = yyzDirMap[path];
		if (dir != null) {
			for (entry in dir.entries) unlinkSync(entry.path);
			yyzDirMap.remove(path);
			var par = yyzDirMap[dir.dir];
			if (par != null) par.entries.remove(dir);
		}
	}
	override function readNodeFileSync(path:String):NodeBuffer {
		throw "Not available here!";
	}
	override public function readTextFile(path:String, fn:Error->String->Void):Void {
		var file = yyzFileMap[fixSlashes(path)];
		JsTools.setImmediate(function() {
			if (file != null) {
				fn(null, file.getText());
			} else fn(new Error("File not found: " + path), null);
		});
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
			yyzGetParentDir(fwpath).entries.push(file);
		} else {
			file.setText(text);
			file.time = t;
		}
	}
	override public function readJsonFile<T:{}>(path:String, fn:Error->T->Void):Void {
		var file = yyzFileMap[fixSlashes(path)];
		JsTools.setImmediate(function() {
			if (file != null) {
				fn(null, Json.parse(file.getText()));
			} else fn(new Error("File not found: " + path), null);
		});
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
	
	#if !gmedit.no_gmx
	override public function readGmxFile(path:String, fn:Error->SfGmx->Void):Void {
		var file = yyzFileMap[fixSlashes(path)];
		JsTools.setImmediate(function() {
			if (file != null) {
				fn(null, SfGmx.parse(file.getText()));
			} else fn(new Error("File not found: " + path), null);
		});
	}
	override public function readGmxFileSync(path:String):SfGmx {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return SfGmx.parse(file.getText());
		} else throw new Error("File not found: " + path);
	}
	#end
	
	override public function getImageURL(path:String):String {
		var file = yyzFileMap[fixSlashes(path)];
		if (file != null) {
			return file.getDataURL();
		} else return null;
	}
	override public function renameSync(prev:String, next:String) {
		prev = fixSlashes(prev);
		next = fixSlashes(next);
		var file:YyZipFile = yyzFileMap[prev];
		if (file != null) {
			var _file_dir = file.dir;
			file.setPath(next);
			yyzFileMap.remove(prev);
			yyzFileMap.set(next, file);
			if (file.dir != _file_dir) {
				var dir = yyzDirMap[_file_dir];
				if (dir != null) dir.entries.remove(file);
				
				dir = yyzGetParentDir(next);
				if (dir.entries.indexOf(file) < 0) {
					dir.entries.push(file);
				}
			}
		} else {
			var dir = yyzDirMap[prev];
			if (dir != null) {
				yyzDirMap.remove(prev);
				yyzDirMap[next] = dir;
				dir.setPath(next);
				for (entry in dir.entries) {
					renameSync(entry.path, next + "/" + entry.fname);
				}
			}
		}
	}
	override public function readdirSync(path:String):Array<ProjectDirInfo> {
		var dir = yyzDirMap[fixSlashes(path)];
		if (dir == null) return [];
		var out = [];
		for (entry in dir.entries) {
			out.push({
				fileName: entry.fname,
				relPath: entry.path,
				fullPath: entry.path,
				isDirectory: (entry is YyZipDir),
			});
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


