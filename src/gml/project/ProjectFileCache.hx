package gml.project;

import js.lib.DataView;
import js.html.Console;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import tools.Dictionary;
import ui.Preferences;
using tools.PathTools;

class ProjectFileCache {
	public static var dirname = "#cache";
	public static var indexPath = dirname + "/texty";
	public static var indexSig32 = ("G".code
		| ("M".code << 8)
		| ("E".code << 16)
		| ("C".code << 24)
	);
	
	public var map:Dictionary<ProjectFileCacheItem> = new Dictionary();
	public var project:Project;
	public var fileTime:Float = 0;
	public var canSave = true;
	public function new(project:Project) {
		this.project = project;
	}
	public inline function get(relPath:String) {
		return map[relPath];
	}
	public inline function set(relPath:String, item:ProjectFileCacheItem) {
		map[relPath] = item;
	}
	
	public function isEnabled() {
		if (project.isVirtual) return false;
		var pref = Preferences.current;
		return pref.assetCache && pref.diskAssetCache.enabled;
	}
	public function onLoad() {
		if (!isEnabled()) return;
		if (fileTime != 0) return;
		
		try {
			var newFileTime = project.mtimeSync(indexPath);
			if (newFileTime == null) return;
			
			var buf = project.readNodeFileSync(indexPath);
			var len = buf.length;
			if (len < 4) return;
			
			if (buf.readInt32LE(0) != indexSig32) return;
			var version = buf.readInt32LE(4);
			if (version > 1) return;
			
			var pos = 8;
			var found = 0;
			while (pos < len) {
				var pathLen = buf.readInt32LE(pos);
				if (pathLen < 0) break;
				var path = buf.getString(pos + 4, pos + 4 + pathLen);
				pos += 4 + pathLen;
				
				var time = buf.readDoubleLE(pos);
				pos += 8;
				
				var textLen = buf.readInt32LE(pos);
				var text = buf.getString(pos + 4, pos + 4 + textLen);
				pos += 4 + textLen;
				
				var item:ProjectFileCacheItem = {
					mtime: time,
					data: text,
					inSync: true,
				};
				map[path] = item;
				found += 1;
				//Console.log(path, time, text);
			}
			
			fileTime = newFileTime;
			Console.log('[ProjectFileCache] Loaded index! $found items.');
		} catch (e:Any) {
			Console.error('[ProjectFileCache] Failed to load "$indexPath":', e);
		}
	}
	public function onSave() {
		if (!isEnabled()) return;
		if (!canSave) return;
		try {
			var curFileTime = project.mtimeSync(indexPath);
			if (curFileTime != null && curFileTime > fileTime) {
				canSave = false;
				return;
			}
			
			var pref = Preferences.current.diskAssetCache;
			var maxSizePerItem = pref.maxSizePerItem;
			var fileExtensions = pref.fileExtensions;
			var allowAnyExtension = fileExtensions.contains("*");
			
			var itemCount = 0;
			var newItemCount = 0;
			map.forEach(function(path, item) {
				var wantSave = item.data.length <= maxSizePerItem;
				if (wantSave) {
					if (allowAnyExtension) {
						// OK!
					} else {
						var ext = path.ptExt();
						wantSave = fileExtensions.contains(ext);
					}
				}
				item.wantSave = wantSave;
				if (wantSave) {
					itemCount += 1;
					if (!item.inSync) newItemCount += 1;
				}
			});
			
			// too few items - don't write index, or even delete index
			if (itemCount < pref.minItemCount) {
				if (curFileTime == null) return; // no file, too few items - all good!
				
				// remove the file
				project.unlinkSync(indexPath);
				Console.log('[ProjectFileCache] Deleted index!');
				return;
			}
			
			// not worth the effort:
			if (newItemCount / itemCount < pref.cacheUpdateThreshold / 100) {
				Console.log('[ProjectFileCache] Not worth writing yet ($newItemCount/$itemCount changed)');
				return;
			}
			
			// make sure that directory exists
			if (!project.existsSync(dirname)) {
				project.mkdirSync(dirname);
				project.writeTextFileSync("#cache/.gitignore", "*");
			}
			
			// header
			var b = new BytesOutput();
			b.writeInt32(indexSig32);
			b.writeInt32(1); // version
			
			// ... items
			map.forEach(function(path, item) {
				if (!item.wantSave) return;
				item.inSync = true;
				var pb = Bytes.ofString(path);
				var db = Bytes.ofString(item.data);
				b.writeInt32(pb.length);
				b.writeBytes(pb, 0, pb.length);
				b.writeDouble(item.mtime);
				b.writeInt32(db.length);
				b.writeBytes(db, 0, db.length);
			});
			b.writeInt32(-1);
			
			// and finally:
			var ab = b.getBytes().getData();
			var v = new DataView(ab, 0, b.length);
			project.writeNodeFileSync(indexPath, v);
			fileTime = project.mtimeSync(indexPath);
			Console.log('[ProjectFileCache] Updated index! $newItemCount/$itemCount new items.');
		} catch (e:Any) {
			Console.error('[ProjectFileCache] Failed to save "$indexPath":', e);
		}
	}
}
typedef ProjectFileCacheItem = {
	var data:String;
	var mtime:Float;
	/** came from a file and has not been changed **/
	var ?inSync:Bool;
	/** temporary for onSave **/
	var ?wantSave:Bool;
}