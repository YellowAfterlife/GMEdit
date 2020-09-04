package ui;
import Main.*;
import electron.Electron;
import electron.FileSystem;
import electron.FileWrap;
import electron.Shell;
import gml.GmlAPI;
import gml.file.GmlFile;
import gml.Project;
import haxe.Constraints.Function;
import haxe.extern.EitherType;
import haxe.io.Path;
import js.lib.RegExp;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.Element;
import js.html.MouseEvent;
import js.html.WheelEvent;
import tools.Dictionary;
import tools.JsTools;
import ui.ChromeTabs;
import ace.AceWrap;
import ace.extern.*;
import ace.extern.AceHashHandler;
import ace.extern.AceCommand;
using StringTools;
using tools.NativeString;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class KeyboardShortcuts {
	public static var hashHandler:AceHashHandler;
	static var hashHandlerCtx:AceHashHandlerKeyContext;
	//
	static var pressedKeys:Dictionary<Int> = new Dictionary();
	static var ctrlAltTimestamp = 0.;
	static var currentEvent:KeyboardEvent;
	
	static function initCommands():Void {
		hashHandler = new AceHashHandler();
		//
		var rxMod = new RegExp("\\bmod\\-");
		var hh = hashHandler;
		function keyToCommandKey(key:String):AceCommandKey {
			if (rxMod.test(key)) {
				return {
					win: key.replaceExt(rxMod, "ctrl-"),
					mac: key.replaceExt(rxMod, "cmd-"),
				};
			} else return key;
		}
		function addCommand(name:String, keys:EitherType<String, Array<String>>, exec:Void->Void):Void {
			var multikey = Std.is(keys, Array);
			var key = multikey ? keys[0] : keys;
			hh.addCommand({
				bindKey: keyToCommandKey(key),
				name: name,
				exec: cast exec,
			});
			if (multikey) {
				var keys:Array<String> = keys;
				for (i in 1 ... keys.length) {
					hh.bindKey(keyToCommandKey(keys[i]), name);
				}
			}
		}
		addCommand("previousTab", ["mod-shift-tab", "mod-pageup"], function() {
			var tab = document.querySelector(".chrome-tab-current");
			if (tab == null) return;
			var next = tab.previousElementSibling;
			if (next == null) next = tab.parentElement.lastElementChild;
			if (next != null) next.click();
		});
		addCommand("nextTab", ["mod-tab", "mod-pagedown"], function() {
			var tab = document.querySelector(".chrome-tab-current");
			if (tab == null) return;
			var next = tab.nextElementSibling;
			if (next == null) next = tab.parentElement.firstElementChild;
			if (next != null) next.click();
		});
		addCommand("toggleDevTools", "mod-shift-i", function() {
			if (Electron == null) return;
			Electron.remote.BrowserWindow.getFocusedWindow().toggleDevTools();
		});
		//
		#if !lwedit
		addCommand("reloadProject", "mod-r", function() {
			if (Project.current != null) {
				Project.current.reload();
			}
		});
		#end
		//
		addCommand("closeTab", "mod-w", function() {
			var q = document.querySelector(".chrome-tab-current .chrome-tab-close");
			if (q != null) {
				q.click();
			} else if (document.querySelectorAll(".chrome-tab").length == 0) {
				Project.open("");
			}
		});
		addCommand("closeOtherTabs", "mod-shift-w", function() {
			for (q in document.querySelectorAll(
				".chrome-tab:not(.chrome-tab-current) .chrome-tab-close"
			)) {
				var qe:Element = cast q; qe.click();
			}
		});
		//
		addCommand("saveTab", "mod-s", function() {
			var q = GmlFile.current;
			if (q != null) q.save();
		});
		addCommand("saveAll", "mod-shift-s", function() {
			for (tabEl in ChromeTabs.impl.tabEls) {
				var file = tabEl.gmlFile;
				if (file != null) file.save();
			}
			#if lwedit
			ui.liveweb.LiveWebState.save();
			#end
		});
		//
		addCommand("localSearch", "mod-f", function() {
			// maybe later
		});
		addCommand("globalSearch", "mod-shift-f", function() {
			GlobalSearch.toggle();
		});
		//
		var lookupPre = Electron != null ? "mod" : "alt";
		addCommand("globalLookup", '$lookupPre-t', function() {
			GlobalLookup.toggle();
		});
		addCommand("commandPalette", '$lookupPre-shift-t', function() {
			GlobalLookup.toggle(">");
		});
		//
		addCommand("switchToLastTab", "mod-9", function() {
			var tabs = document.querySelectorEls(".chrome-tab");
			var tabEl:Element = tabs[tabs.length - 1];
			if (tabEl != null) tabEl.click();
		});
		for (i in 1 ... 9) {
			addCommand('switchToTab$i', 'mod-$i', function() {
				var tabs = document.querySelectorEls(".chrome-tab");
				var tabEl:Element = cast tabs[i - 1];
				if (tabEl != null) tabEl.click();
			});
		}
	}
	
	static function handleKey(e:KeyboardEvent, hashId:Int, keyCode:Int) {
		var keyString = AceKeys.keyCodeToString(keyCode);
		var result = hashHandler.handleKeyboard(hashHandlerCtx, hashId, keyString, keyCode);
		if (result == null
			|| result.command == null
			|| result.command == "null" // see this.$callKeyboardHandlers in ace.js
		) return null;
		var command:AceCommand;
		if (Std.is(result.command, String)) {
			command = hashHandler.commands[result.command];
		} else command = result.command;
		if (command == null) return null;
		currentEvent = e;
		e.preventDefault();
		command.exec(aceEditor);
		currentEvent = null;
		return false;
	}
	
	/**
	 * Pretty much a replica of Ace's normalizeCommandKeys
	 */
	static function normalizeCommandKeys(e:KeyboardEvent, keyCode:Int) {
		var hashId = 0 | (e.ctrlKey ? 1 : 0) | (e.altKey ? 2 : 0) | (e.shiftKey ? 4 : 0) | (e.metaKey ? 8 : 0);
		inline function getLocation():Int {
			var location = e.location;
			if (location == null) location = Reflect.field(e, "keyLocation");
			return location;
		}
		// AltGr shenanigans
		if (!AceUserAgent.isMac) {
			if (e.getModifierState("OS") || e.getModifierState("Win")) hashId |= 8;
			if (pressedKeys["altGr"] > 0) {
				if ((hashId & 3) != 3) {
					pressedKeys["altGr"] = 0;
				} else return false;
			}
			if (keyCode == KeyboardEvent.DOM_VK_CONTROL || keyCode == KeyboardEvent.DOM_VK_ALT) {
				var location = getLocation();
				if (keyCode == KeyboardEvent.DOM_VK_CONTROL && location == 1) {
					if (pressedKeys["" + keyCode] == 1) ctrlAltTimestamp = e.timeStamp;
				} else if (keyCode == KeyboardEvent.DOM_VK_ALT && hashId == 3 && location == 2) {
					var dt = e.timeStamp - ctrlAltTimestamp;
					if (dt < 50) pressedKeys["altGr"] = 1;
				}
			}
		}
		//
		switch (keyCode) {
			case KeyboardEvent.DOM_VK_SHIFT,
				KeyboardEvent.DOM_VK_CONTROL,
				KeyboardEvent.DOM_VK_ALT,
				KeyboardEvent.DOM_VK_META
			: keyCode = -1;
		}
		// Windows, Menu, ?
		if ((hashId & 8) != 0 && (keyCode >= 91 && keyCode <= 93)) keyCode = -1;
		// a different Enter key..?
		if (hashId == 0 && keyCode == 13) {
			var location = getLocation();
			if (location == 3) {
				handleKey(e, hashId, -keyCode);
				if (e.defaultPrevented) return null;
			}
		}
		// some Chrome OS hack?
		if (AceUserAgent.isChromeOS && (hashId & 8) != 0) {
			handleKey(e, hashId, keyCode);
			if (e.defaultPrevented) return null;
			hashId &= ~8;
		}
		// illegal key?
		if (hashId == 0
			&& !AceKeys.FUNCTION_KEYS.exists(keyCode)
			&& !AceKeys.PRINTABLE_KEYS.exists(keyCode)
		) return false;
		// OK?
		return handleKey(e, hashId, keyCode);
	}
	//
	static function initSystemButtons(closeButton:Element) {
		if (closeButton == null) return;
		inline function getCurrentWindow():Dynamic {
			return Electron.remote.getCurrentWindow();
		}
		closeButton.addEventListener("click", function(_) {
			var wnd = getCurrentWindow();
			if (wnd != null) wnd.close();
		});
		document.querySelector(".system-button.maximize").addEventListener("click", function(_) {
			var wnd = getCurrentWindow();
			if (wnd != null) {
				if (wnd.isMaximized()) {
					wnd.unmaximize();
				} else wnd.maximize();
			}
		});
		document.querySelector(".system-button.minimize").addEventListener("click", function(_) {
			var wnd = getCurrentWindow();
			if (wnd != null) wnd.minimize();
		});
	}
	public static function initGlobal() {
		hashHandlerCtx = new AceHashHandlerKeyContext(aceEditor);
		initCommands();
		//
		var lastDefaultPrevented:Bool = null;
		document.body.addEventListener("keydown", function(e:KeyboardEvent) {
			var kcs = Std.string(e.keyCode);
			pressedKeys[kcs] = JsTools.or(pressedKeys[kcs], 0) + 1;
			var result = normalizeCommandKeys(e, e.keyCode);
			lastDefaultPrevented = e.defaultPrevented;
			return result;
		});
		document.body.addEventListener("keypress", function(e:KeyboardEvent) {
			if (lastDefaultPrevented && (e.ctrlKey || e.altKey || e.shiftKey || e.metaKey)) {
				e.stopPropagation();
				e.preventDefault();
				lastDefaultPrevented = null;
			}
		});
		document.body.addEventListener("keyup", function(e:KeyboardEvent) {
			pressedKeys[Std.string(e.keyCode)] = null;
		});
		window.addEventListener("focus", function() {
			pressedKeys = new Dictionary();
		});
		//
		editors.EditKeybindings.initGlobal();
		initSystemButtons(document.querySelector(".system-button.close"));
	}
	public static function initEditor(editor:AceWrap) {
		editor.on("mousedown", function(ev:Dynamic) {
			var dom:MouseEvent = ev.domEvent;
			if (dom.button != 1) return;
			var pos:AcePos = ev.getDocumentPosition();
			var session = editor.session;
			var line = session.getLine(pos.row);
			if (line != null && pos.column < line.length
				&& OpenDeclaration.proc(session, pos, session.getTokenAtPos(pos))
			) {
				if (session.selection.isEmpty()) {
					session.selection.moveTo(pos.row, pos.column);
				}
				dom.preventDefault();
			}
		});
		editor.on("mousewheel", function(ev:Dynamic) {
			var dom:WheelEvent = ev.domEvent;
			if (Preferences.current.ctrlWheelFontSize) do {
				if (!dom.ctrlKey && !dom.metaKey) break;
				var delta = dom.deltaY;
				if (delta == 0) break;
				delta = delta < 0 ? 1 : -1;
				editor.setOption("fontSize", editor.getOption("fontSize") + delta);
			} while (false);
		});
		(editor:Dynamic).debugShowToken = function() {
			editor.on("mousemove", function(ev:Dynamic) {
				var pos:AcePos = ev.getDocumentPosition();
				var tk = editor.session.getTokenAtPos(pos);
				if (tk == null) return;
				var sb = editor.statusBar;
				if (sb == null) return;
				sb.setText(haxe.Json.stringify(tk));
			});
		};
	}
}

typedef HasKeyboardFlags = {
	public var ctrlKey (default, null):Bool;
	public var shiftKey(default, null):Bool;
	public var altKey  (default, null):Bool;
	public var metaKey (default, null):Bool;
};
