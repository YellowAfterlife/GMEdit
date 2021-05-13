package electron;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_App") extern class AppTools {
	static function getPath(kind:String):String;
	
	/** Windows-only! */
	static function setUserTasks(arr:Array<AppUserTask>):Void;
	
	/** Windows, Mac */
	static inline function addRecentDocument(path:String):Void {
		IPC.send('add-recent-document', path);
	}
	
	/** Windows, Mac */
	static inline function clearRecentDocuments():Void {
		IPC.send('clear-recent-documents');
	}
}
typedef AppUserTask = {
	var program:String;
	var arguments:String;
	var iconPath:String;
	var iconIndex:Int;
	var title:String;
	var description:String;
}