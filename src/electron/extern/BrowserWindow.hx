package electron.extern;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_BrowserWindow")
extern class BrowserWindow {
	/**
		Try to close the window. This has the same effect as a user manually clicking
		the close button of the window. The web page may cancel the close though. See
		the close event.
	**/
	function close():Void;
	
	/**
		Whether the window is in fullscreen mode.
	**/
	function isFullScreen():Bool;
	
	/**
		Sets whether the window should be in fullscreen mode.
	**/
	function setFullScreen(flag:Bool):Void;
	
	var fullScreen : Bool;
	
	/**
		Sets the background color of the window. See Setting `backgroundColor`.
	**/
	function setBackgroundColor(backgroundColor:String):Void;
	
	/**
		The window that is focused in this application, otherwise returns `null`.
	**/
	static function getFocusedWindow():Null<BrowserWindow>;
	
	function toggleDevTools():Void;
}