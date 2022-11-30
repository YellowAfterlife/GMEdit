package ui.miniweb;
import ui.miniweb.MiniWebRunnerAPI;

/**
 * ...
 * @author 
 */
@:keep @:expose("GMEditMini")
class MiniWebEditorAPI {
	public static function hookFunction(name:String, hook:MiniWebHook):Void {
		MiniWeb.funcHooks[name] = hook;
		if (MiniWeb.runnerAPI != null) {
			MiniWeb.runnerAPI.hookFunction(name, hook);
		}
	}
	public static function printAST():Dynamic {
		var str = MiniWeb.runnerAPI != null ? MiniWeb.runnerAPI.printAST() : null;
		return str != null ? haxe.Json.parse(str) : null;
	}
	
	/** This function may use printAST to inspect the code and return an error if it does not match requirements. */
	public static dynamic function onCompile(cr:MiniWebCompileResult):MiniWebCompileResult {
		return cr;
	}
	
	/** Executes after running through entrypoint code. */
	public static dynamic function onRun(rr:MiniWebCallResult):Void {}
	public static dynamic function onCallError(errorText:String, errorPos:MiniWebPos):Void {}
	public static var stopOnError:Bool = true;
}