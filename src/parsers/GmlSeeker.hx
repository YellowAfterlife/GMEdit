package parsers;
import electron.FileWrap;
import file.FileKind;
import gml.GmlAPI;
import gml.*;
import js.lib.Error;
import js.html.Console;
import parsers.GmlSeekData;
import parsers.seeker.GmlSeekerImpl;
import tools.Aliases;
using StringTools;
using tools.NativeString;
using tools.NativeArray;
using tools.PathTools;

/**
 * Looks for definitions in files/code (for syntax highlighing, auto-completion, etc.)
 * @author YellowAfterlife
 */
class GmlSeeker {
	public static var itemsLeft:Int = 0;
	static var itemQueue:Array<GmlSeekerItem> = [];
	static var lastLabelUpdateTime:Float = 0;
	public static function start() {
		itemsLeft = 0;
		itemQueue.resize(0);
	}
	private static function runItem(item:GmlSeekerItem) {
		itemsLeft++;
		FileWrap.readTextFile(item.path, function ready(err:Error, text:String) {
			if (err != null) {
				if ((cast err).errno == -4058) {
					Console.warn("Can't index `" + item.path + "` - file is missing.");
				} else {
					Console.error("Can't index `" + item.path + "`:", err);
				}
				runNext();
			} else try {
				if (runSync(item.path, text, item.main, item.kind)) {
					runNext();
				}
			} catch (ex:Dynamic) {
				Console.error("Can't index `" + item.path + "`:", ex);
				runNext();
			}
		});
	}
	public static function run(path:FullPath, main:GmlName, kind:FileKind) {
		var item:GmlSeekerItem = {path:path.ptNoBS(), main:main, kind:kind};
		if (itemsLeft < ui.Preferences.current.assetIndexBatchSize) {
			runItem(item);
		} else itemQueue.push(item);
	}
	public static function runFinish():Void {
		GmlAPI.gmlComp.autoSort();
		var pj = Project.current;
		if (pj != null && pj.isIndexing) {
			pj.isIndexing = false;
			pj.finishedIndexing();
			Main.aceEditor.session.bgTokenizer.start(0);
		}
	}
	public static function runNext():Void {
		var left = --itemsLeft;
		var item = itemQueue.shift();
		var now = Date.now().getTime();
		if (lastLabelUpdateTime < now - 333) {
			lastLabelUpdateTime = now;
			Project.nameNode.innerText = 'Indexing (${itemQueue.length})...';
		}
		if (item != null) {
			runItem(item);
		} else if (left <= 0) {
			runFinish();
		}
	}
	
	public static function runSyncImpl(
		orig:FullPath, src:GmlCode, main:String, out:GmlSeekData, locals:GmlLocals, kind:FileKind
	):Void {
		var seeker = new GmlSeekerImpl(orig, src, main, out, locals, kind);
		seeker.run();
	}
	
	public static function finish(orig:String, out:GmlSeekData):Void {
		GmlSeekData.apply(orig, GmlSeekData.map[orig], out);
		GmlSeekData.map.set(orig, out);
		out.comps.nameSort();
	}
	public static function addObjectChild(parentName:String, childName:String) {
		var pj = Project.current;
		pj.objectParents[childName] = parentName;
		var parChildren = pj.objectChildren[parentName];
		if (parChildren == null) {
			parChildren = [];
			pj.objectChildren.set(parentName, parChildren);
		}
		parChildren.push(childName);
	}
	public static function runSync(path:String, content:String, main:String, kind:FileKind) {
		return kind.index(path, content, main, false);
	} // runSync
}

typedef GmlSeekerItem = {
	path:String,
	main:String,
	kind:FileKind,
}
