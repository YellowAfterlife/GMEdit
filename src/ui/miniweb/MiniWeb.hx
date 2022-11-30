package ui.miniweb;
import Main.window;
import Main.document;
import gml.file.GmlFile;
import js.html.IFrameElement;
import js.html.KeyboardEvent;
import tools.Dictionary;
import ui.miniweb.MiniWebRunnerAPI;
import ui.liveweb.*;
import ui.miniweb.MiniWebEditorAPI;
using tools.HtmlTools;

/**
 * ...
 * @author 
 */
class MiniWeb {
	public static var running:Bool;
	public static var runnerAPI:MiniWebRunnerAPI;
	static var iframe:IFrameElement;
	static var ignoreBlank:Bool = false;
	static inline var blankURL = "about:blank";
	static var nextName:String;
	static var nextCode:String = null;
	public static var funcHooks:Dictionary<MiniWebHook> = new Dictionary();
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
	static function run_1(api:MiniWebRunnerAPI) {
		//Console.log(api);
		runnerAPI = api;
		api.hookFunction("game_end", function(self, other, args, orig) { stop(); return null; });
		for (name => hook in funcHooks) {
			api.hookFunction(name, hook);
		}
		var cr = api.compile([{ name: nextName, main: "", code: nextCode }]);
		cr = MiniWebEditorAPI.onCompile(cr);
		if (cr.errorText == null) {
			var rr = api.call("");
			MiniWebEditorAPI.onRun(rr);
			if (rr.status != "done"){
				showError(rr.result, rr.errorPos);
				if (MiniWebEditorAPI.stopOnError) stop();
			} else {
				api.onCallError = function(errorText, errorPos) {
					MiniWebEditorAPI.onCallError(errorText, errorPos);
					if (MiniWebEditorAPI.stopOnError) {
						showError(errorText, errorPos);
						stop();
					}
				}
			}
			Console.log(rr);
		} else {
			showError(cr.errorText, cr.errorPos);
		}
	}
	static function iframeHandler(_) {
		running = iframe.src != blankURL;
		runnerAPI = null;
		if (!running) {
			if (ignoreBlank) {
				ignoreBlank = false;
				return;
			}
			iframe.src = "livejs-mini/index.html";
			return;
		}
		var api:MiniWebRunnerAPI = (cast iframe.contentWindow).GMLiveAPI;
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
		ignoreBlank = false;
		iframe.src = blankURL;
		return true;
	}
	public static function stop() {
		ignoreBlank = true;
		iframe.src = blankURL;
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