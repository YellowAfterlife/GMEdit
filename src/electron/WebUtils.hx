package electron;
import js.html.File;

/**
	This seems to be mostly here to break your old apps once.
	https://www.electronjs.org/docs/latest/api/web-utils
**/
extern class WebUtils {
	function getPathForFile(file:File):String;
}