package ui.liveweb;
import Main.window;
import Main.document;
import gml.file.GmlFile;
import js.html.IFrameElement;
import js.html.KeyboardEvent;
import ui.liveweb.MiniWebAPI;
using tools.HtmlTools;

/**
 * ...
 * @author 
 */
class MiniWeb {
	static var iframe:IFrameElement;
	static var ignoreBlank:Bool = false;
	static var nextName:String;
	static var nextCode:String = null;
	public static function readyUp() {
		LiveWebState.finish();
	}
	static function showError(errorText:String, errorPos:MiniWebPos) {
		LiveWebTools.showError({
			file: errorPos.name,
			row: errorPos.row - 1,
			column: errorPos.col - 1,
			text: errorText,
			error: null,
		});
	}
	static function run_1(api:MiniWebAPI) {
		Console.log(api);
		var cr = api.compile([{ name: nextName, main: "", code: nextCode }]);
		Console.log(cr);
		if (cr.errorText == null) {
			var rr = api.call("");
			Console.log(rr);
		} else {
			showError(cr.errorText, cr.errorPos);
		}
	}
	static function iframeHandler(_) {
		if (iframe.src == "about:blank") {
			if (ignoreBlank) {
				ignoreBlank = false;
				return;
			}
			iframe.src = "livejs-mini/index.html";
			return;
		}
		var api:MiniWebAPI = (cast iframe.contentWindow).GMLiveAPI;
		if (api != null) {
			run_1(api);
		} else {
			(cast iframe.contentWindow).GMLiveAPI_onload = run_1;
		}
	}
	public static function run() {
		var file = GmlFile.current;
		if (file == null) return false;
		var codeEditor = file.codeEditor;
		if (codeEditor == null) return false;
		file.save();
		nextName = file.name;
		nextCode = codeEditor.session.getValue();
		iframe.src = "about:blank";
		return true;
	}
	public static function init() {
		iframe = document.querySelectorAuto("#game");
		iframe.onload = iframeHandler;
		window.addEventListener("keydown", function(e:KeyboardEvent) {
			if (e.keyCode == 116 || (e.keyCode == 13 && e.ctrlKey)) {
				run();
				e.preventDefault();
				e.stopPropagation();
			}
		});
		//
		LiveWebState.init();
	}
}