package electron;
import js.html.FileList;
import js.html.FormElement;
import js.html.InputElement;
import js.html.File;
import js.html.Uint8Array;

/**
 * https://electronjs.org/docs/api/dialog
 * @author YellowAfterlife
 */
@:native("Electron_Dialog") extern class Dialog {
	public static function showMessageBox(options:DialogMessageOptions, ?async:Int->Bool->Void):Int;
	
	public static function showOpenDialog(
		options:DialogOpenOptions, ?async:Array<String>->Void
	):Array<String>;
	
	public static inline function showOpenDialogWrap(
		options:DialogOpenOptions, func:FileList->Void
	):Void {
		DialogFallback.showOpenDialogWrap(options, func);
	}
	
	/*public static inline function showConfirmBoxSync(text:String, title:String) {
		//if (Dialog 
	}*/
}
@:keep class DialogFallback {
	private static var form:FormElement;
	private static var input:InputElement;
	public static function showOpenDialogWrap(
		options:DialogOpenOptions, func:FileList->Void
	):Void {
		if (Electron != null) {
			Dialog.showOpenDialog(options, function(paths:Array<String>) {
				var files:Array<File> = [];
				for (path in paths) {
					var raw = FileSystem.readFileSync(path);
					var ua:Uint8Array = untyped Uint8Array.from(raw);
					var abuf = ua.buffer;
					files.push(new File(abuf, {
						name: path
					}));
				}
				func(cast files);
			});
			return;
		}
		if (form == null) init();
		if (options.filters != null) {
			var accept = [];
			for (filter in options.filters) {
				for (ext in filter.extensions) accept.push("." + ext);
			}
			input.accept = accept.join(",");
		} else input.accept = null;
		form.reset();
		input.onchange = function(_) {
			if (input.files.length > 0) func(input.files);
		};
		input.click();
	}
	public static function showOpenDialog(
		options:DialogOpenOptions, ?async:Array<String>->Void
	):Array<String> {
		return null;
	}
	static function init() {
		//
		form = Main.document.createFormElement();
		input = Main.document.createInputElement(); 
		input.type = "file";
		form.appendChild(input);
		form.style.display = "none";
		Main.document.body.appendChild(form);
	}
}
//
typedef DialogOpenOptions = {
	?title:String,
	?defaultPath:String,
	?buttonLabel:String,
	?filters:Array<DialogFilter>,
	?properties:Array<DialogOpenFeature>,
};
@:forward abstract DialogFilter(DialogFilterImpl)
from DialogFilterImpl to DialogFilterImpl {
	public inline function new(name:String, extensions:Array<String>) {
		this = { name: name, extensions: extensions };
	}
}
private typedef DialogFilterImpl = {name:String, extensions:Array<String>};

@:build(tools.AutoEnum.build("nq"))
@:enum abstract DialogOpenFeature(String) from String to String {
	var openFile;
	var openDirectory;
	var multiSelections;
	var showHiddenFiles;
	var createDirectory;
	var promptToCreate;
	var noResolveAliases;
	var treatPackageAsDirectory;
}
//
typedef DialogMessageOptions = {
	?type:DialogMessageType,
	buttons:Array<String>,
	message:String,
	?title:String,
	?detail:String,
	?checkboxLabel:String,
	?cancelId:Int,
	?defaultId:Int,
};
@:build(tools.AutoEnum.build("lq"))
@:enum abstract DialogMessageType(String) from String to String {
	var None;
	var Info;
	var Error;
	var Question;
	var Warning;
}
