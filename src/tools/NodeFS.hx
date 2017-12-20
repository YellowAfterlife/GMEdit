package tools;
import gmx.SfGmx;
import js.Error;
import haxe.extern.EitherType;

/**
 * ...
 * @author YellowAfterlife
 */
extern class NodeFS {
	public function readFile(path:String, enc:String, callback:Error->Dynamic->Void):Void;
	public inline function readTextFile(path:String, callback:Error->String->Void):Void {
		readFile(path, "utf8", cast callback);
	}
	public function readFileSync(path:String, ?enc:String):Dynamic;
	public inline function readTextFileSync(path:String):String {
		return readFileSync(path, "utf8");
	}
	public inline function readGmxFileSync(path:String):SfGmx {
		return SfGmx.parse(readTextFileSync(path));
	}
	public function writeFileSync(path:String, data:Dynamic, ?options:Dynamic):Void;
}
