package editors;
import Main.document;
import ace.AceWrap;
import ace.extern.AceCommand;
import ace.extern.AceHashHandler;
import editors.Editor;
import gml.file.GmlFile;
import haxe.DynamicAccess;
import js.html.TableElement;
import js.html.TableRowElement;
import js.lib.Map in JsMap;
import js.lib.RegExp;
import tools.Dictionary;
import tools.JsTools;
import tools.NativeObject;
import tools.NativeString;
import ui.KeyboardShortcuts;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class EditKeybindings extends Editor {
	/*
	aceEditor.commands.bindKey to rebind
	aceEditor.commands.commandKeyBinding for current
	aceEditor.commands.commands for available commands
	*/
	static var defaultBindings:DynamicAccess<Dictionary<Array<String>>> = {};
	
	public static function concatBindings(arr:Array<String>, ?sort:Bool):String {
		if (arr == null || arr.length == 0) return "";
		var pretty = [];
		for (key in arr) pretty.push(AceCommandKey.prettyprint(key));
		if (sort) pretty.sort((a, b) -> a < b ? -1 : 1);
		return pretty.join(" | ");
	}
	public static function splitBindings(s:String):Array<String> {
		if (NativeString.trimBoth(s) == "") return [];
		var arr = s.split("|");
		for (i in 0 ... arr.length) {
			arr[i] = NativeString.trimBoth(arr[i]);
		}
		return arr;
	}
	
	var table:TableElement;
	function addSection(hh:AceHashHandler, title:String, section:String) {
		var headRow = document.createTableSectionElement();
		var headCell = document.createTableCellElement();
		headCell.innerText = title;
		headCell.colSpan = 4;
		headRow.appendChild(headCell);
		table.appendChild(headRow);
		//
		//var bindings = hh.getKeybindingsPerCommand();
		var defaults = defaultBindings[section];
		if (defaults == null) defaults = {};
		var custom = Preferences.current.customizedKeybinds[section];
		var customSet = custom != null;
		if (!customSet) custom = {};
		var first = true;
		//
		hh.commands.forEach(function(name, cmd) {
			var tr = document.createTableRowElement();
			
			//
			var fd = document.createInputElement();
			fd.type = "text";
			
			var fdDef:String;
			if (defaults[name] == null) {
				fdDef = cmd.bindKey.key;
				if (fdDef == null) {
					fdDef = "";
					defaults[name] = [];
				} else defaults[name] = [fdDef];
			} else fdDef = concatBindings(defaults[name]);
			
			var fdVal = concatBindings(custom[name]);
			fd.placeholder = fdDef;
			if (fdVal != fdDef) fd.value = fdVal;
			
			function sync() {
				var val = fd.value;
				var arr:Array<String>;
				if (val == "") {
					custom.remove(name);
					arr = defaults[name];
				} else {
					arr = splitBindings(val);
					custom[name] = arr;
					if (!customSet) {
						customSet = true;
						Preferences.current.customizedKeybinds[section] = custom;
					}
				}
				//
				hh.removeKeybindingsForCommand(name);
				for (item in arr) {
					hh.bindKey(item, name);
				}
				//
				Preferences.save();
			}
			fd.onchange = function(_) sync();
			
			//
			var td = document.createTableCellElement();
			if (first) td.width = "33%";
			var title = cmd.title;
			if (title == null) {
				title = NativeString.capitalize(name);
				title = NativeString.replaceExt(title,
					JsTools.rx(~/-([a-z])/g),
					(_, a) -> " " + a.toUpperCase());
				title = NativeString.replaceExt(title,
					JsTools.rx(~/([a-z])([A-Z0-9])/g),
					(_, a, b) -> a + " " + b.toUpperCase());
			}
			if (cmd.description != null) td.title = cmd.description;
			td.innerText = title;
			tr.appendChild(td);
			
			//
			td = document.createTableCellElement();
			if (first) td.width = "1%";
			var btReset = document.createInputElement();
			btReset.type = "button";
			btReset.onclick = function(_) { fd.value = ""; sync(); }
			btReset.title = "Reset to default";
			btReset.value = "↶";
			td.appendChild(btReset);
			tr.appendChild(td);
			
			//
			td = document.createTableCellElement();
			if (first) td.width = "1%";
			var btClear = document.createInputElement();
			btClear.type = "button";
			btClear.onclick = function(_) { fd.value = " "; sync(); }
			btClear.title = "Clear";
			btClear.value = "⌧";
			td.appendChild(btClear);
			tr.appendChild(td);
			
			//
			td = document.createTableCellElement();
			td.appendChild(fd);
			tr.appendChild(td);
			//
			table.appendChild(tr);
			first = false;
		});
	}
	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		element.id = "keybindings-editor";
		element.classList.add("popout-window");
		table = document.createTableElement();
		element.append(table);
		addSection(KeyboardShortcuts.hashHandler, "Global", "global");
		addSection(Main.aceEditor.commands, "Code Editor", "codeEditor");
	}
	static function initHandler(hh:AceHashHandler, category:String) {
		if (defaultBindings[category] == null) {
			defaultBindings[category] = hh.getKeybindingsPerCommand();
		}
		var map = Preferences.current.customizedKeybinds[category];
		if (map == null) return;
		for (cmd => keys in map) {
			hh.removeKeybindingsForCommand(cmd);
			for (key in keys) hh.bindKey(key, cmd);
		}
	}
	public static function initEditor(editor:AceWrap):Void {
		initHandler(editor.commands, "codeEditor");
	}
	public static function initGlobal():Void {
		initHandler(KeyboardShortcuts.hashHandler, "global");
	}
	public static function open():Void {
		for (tab in ui.ChromeTabs.getTabs()) {
			if (Std.is(tab.gmlFile.editor, EditKeybindings)) {
				tab.click();
				return;
			}
		}
		var file = new GmlFile("Keyboard Shortcuts", null, file.kind.misc.KKeybindings.inst);
		GmlFile.openTab(file);
	}
}
