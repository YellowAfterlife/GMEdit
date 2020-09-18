package electron;
import js.html.CustomEvent;
import js.html.Element;
import js.html.FileList;
import js.html.FormElement;
import js.html.InputElement;
import js.html.File;
import js.html.KeyboardEvent;
import js.lib.Promise;
import js.lib.Uint8Array;
import Main.document;

class Dialog {
	
	/**
	 * The most advanced dialog box you can get.
	 * Only available on Electron.
	 */
	public static function showMessageBox(options:DialogMessageOptions, ?async:Int->Bool->Void):Int {
		if (Electron == null) {
			Main.console.error("Don't have a showMessageBox here");
			return -1;
		} else if (async != null) {
			Electron_Dialog.showMessageBox(options).then(function(result) {
				async(result.response, result.checkboxChecked);
			});
			return -1;
		} else return Electron_Dialog.showMessageBoxSync(options);
	}
	
	/**
	 * Shows a generic message box.
	 */
	public static function showAlert(message:String):Void {
		if (Electron != null) {
			Electron_Dialog.showMessageBoxSync({
				type: "info",
				message: message,
				buttons: ["OK"],
			});
		} else Main.window.alert(message);
	}
	
	/**
	 * Shows a message with an error indicator.
	 * Generally used for reporting errors.
	 */
	public static function showError(message:String):Void {
		if (Electron != null) {
			Electron_Dialog.showMessageBoxSync({
				type: "error",
				message: message,
				buttons: ["OK"],
			});
		} else Main.window.alert("❌ " + message);
	}
	
	/**
	 * Shows a yes/no dialog box.
	 */
	public static function showConfirm(text:String):Bool {
		if (Electron != null) {
			return Electron_Dialog.showMessageBoxSync({
				type: "question",
				message: text,
				buttons: ["Yes", "No"],
			}) == 0;
		} else return Main.window.confirm(text);
	}
	
	/**
	 * Shows a yes/no dialog box with a warning sign of some sort.
	 * Generally used for confirmations that may result in loss of work.
	 */
	public static function showConfirmWarn(text:String):Bool {
		if (Electron != null) {
			return Electron_Dialog.showMessageBoxSync({
				type: "warning",
				message: text,
				buttons: ["Yes", "No"],
			}) == 0;
		} else return Main.window.confirm("⚠ " + text);
	}
	
	public static function showOpenDialog(options:DialogOpenOptions, ?async:Array<String>->Void):Array<String> {
		if (Electron == null) {
			Main.console.log("Don't have sync showOpenDialog here");
			return null;
		} else if (async != null) {
			Electron_Dialog.showOpenDialog(options).then(function(result) {
				async(result.canceled ? null : result.filePaths);
			});
			return null;
		} else return Electron_Dialog.showOpenDialogSync(options);
	}
	
	//{
	private static var form:FormElement;
	private static var input:InputElement;
	public static function showOpenDialogWrap(
		options:DialogOpenOptions, func:FileList->Void
	):Void {
		if (Electron != null) {
			showOpenDialog(options, function(paths:Array<String>) {
				var files:Array<File> = [];
				if (paths != null) for (path in paths) {
					var raw = FileSystem.readFileSync(path);
					var ua:Uint8Array = untyped Uint8Array.from(raw);
					var abuf = ua.buffer;
					files.push(new File(cast abuf, cast {
						name: path
					}));
				}
				func(cast files);
			});
			return;
		}
		if (form == null) initDialog();
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
	
	static function initDialog() {
		//
		form = document.createFormElement();
		input = document.createInputElement(); 
		input.type = "file";
		form.appendChild(input);
		form.style.display = "none";
		Main.document.body.appendChild(form);
	}
	//}
	
	//
	static var promptCtr:Element;
	static var promptSpan:Element;
	static var promptInput:InputElement;
	static var promptFunc:String->Void;
	public static function showPrompt(text:String, def:String, fn:String->Void):Void {
		if (promptCtr == null) initPrompt();
		promptFunc = fn;
		tools.HtmlTools.setInnerText(promptSpan, text);
		promptInput.value = def;
		promptFunc = fn;
		promptCtr.style.display = "";
		promptInput.focus();
		promptInput.select();
	}
	static function initPrompt() {
		function proc(ok:Bool):Void {
			var fn = promptFunc; promptFunc = null;
			promptCtr.style.display = "none";
			fn(ok ? promptInput.value : null);
		}
		promptCtr = document.createDivElement();
		promptCtr.id = "lw_prompt";
		promptCtr.className = "lw_modal";
		promptCtr.style.display = "none";
		document.body.appendChild(promptCtr);
		//
		var overlay = document.createDivElement();
		overlay.className = "overlay";
		overlay.addEventListener("click", function(_) proc(false));
		promptCtr.appendChild(overlay);
		//
		var promptw = document.createDivElement();
		promptw.className = "window";
		promptCtr.appendChild(promptw);
		//
		promptSpan = document.createSpanElement();
		promptw.appendChild(promptSpan);
		promptw.appendChild(document.createBRElement());
		//
		promptInput = document.createInputElement();
		promptInput.type = "text";
		promptInput.addEventListener("keydown", function(e:KeyboardEvent) {
			switch (e.keyCode) {
				case KeyboardEvent.DOM_VK_RETURN: proc(true);
				case KeyboardEvent.DOM_VK_ESCAPE: proc(false);
			}
		});
		promptw.appendChild(promptInput);
		//
		var buttons = document.createDivElement();
		buttons.className = "buttons";
		promptw.appendChild(buttons);
		//
		for (z in [true, false]) {
			var bt = document.createInputElement();
			bt.type = "button";
			bt.addEventListener("click", function(_) proc(z));
			bt.value = z ? "OK" : "Cancel";
			if (!z) buttons.appendChild(document.createTextNode(" "));
			buttons.appendChild(bt);
		}
	}
	
	public static function initWorkarounds() {
		// https://github.com/electron/electron/issues/20400
		untyped js.Browser.window.alert = function(text) {
			Electron_Dialog.showMessageBoxSync({
				message: text,
				buttons: ["OK"],
			});
		};
		untyped js.Browser.window.confirm = function(text) {
			return Electron_Dialog.showMessageBoxSync({
				type: "question",
				message: text,
				buttons: ["OK", "Cancel"],
			}) == 0;
		};
	}
}

/**
 * https://electronjs.org/docs/api/dialog
 * @author YellowAfterlife
 */
@:native("Electron_Dialog") extern class Electron_Dialog {
	public static function showMessageBox(options:DialogMessageOptions):Promise<DialogPromiseProps>;
	public static function showMessageBoxSync(options:DialogMessageOptions):Int;
	
	public static function showOpenDialog(options:DialogOpenOptions):Promise<DialogOpenFileResult>;
	public static function showOpenDialogSync(options:DialogOpenOptions):Array<String>;
}

//
typedef DialogPromiseProps = { response:Int, checkboxChecked:Bool };
typedef DialogOpenFileResult = { canceled:Bool, filePaths:Array<String> };
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
