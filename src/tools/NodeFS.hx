package tools;
import js.Error;

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
}
