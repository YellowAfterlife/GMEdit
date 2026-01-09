package ui.misc;

import js.html.MouseEvent;
import js.html.Console;
import js.html.ClipboardEvent;
import js.Browser;

/**
	X11 sabotage
**/
class LinuxPaste {
	static var delay = 200;
	static var allowAfter = 0.0;
	static var updateOnMouseUp = false;
	static inline function getTime():Float {
		return Date.now().getTime();
	}
	public static function prevent(isMouseDown:Bool = true) {
		allowAfter = getTime() + delay;
		updateOnMouseUp = isMouseDown;
	}
	public static function isAllowed(e:ClipboardEvent) {
		var t = getTime();
		//Console.log(t, allowAfter, allowAfter - t);
		return t >= allowAfter;
	}
	public static function init() {
		Browser.document.addEventListener("mouseup", function(e:MouseEvent) {
			if (e.button == 1 && updateOnMouseUp) {
				updateOnMouseUp = false;
				allowAfter = getTime() + delay;
				//Console.log("release", allowAfter);
			}
		});
		Browser.document.addEventListener("paste", function(e:ClipboardEvent) {
			if (!isAllowed(e)) {
				//Console.log("Don't");
				e.preventDefault();
				return false;
			}
			return null;
		});
	}
}