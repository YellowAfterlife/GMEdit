package ace;

import haxe.DynamicAccess;
import electron.Electron;
import js.html.CustomEvent;
import ace.extern.AceSession;
import js.html.Element;
import js.Browser;
import editors.EditCode;
import js.html.Window;
using tools.HtmlTools;

class AcePopout {
	public var window:Window;
	public var editor:AceWrap;
	public var session:AceSession;
	public function new() {
		
	}
	public function bind(q:EditCode) {
		window = Browser.window.open("index-ace-only.html", "", "width=1080,height=960");
		function ready() {
			window.document.title = q.file.name;
			//electron.extern.BrowserWindow.getFocusedWindow().toggleDevTools();
			// just copy everything over for now:
			for (el in Browser.document.querySelectorAllAuto("link, style", Element)) {
				window.document.head.appendChild(el.cloneNode(true));
			}
			editor = new AceWrap(window.document.querySelector("#source"), {
				//window: window,
				create: (el) -> {
					return (cast window).ace.edit(el);
				}
			});
			// set some globals:
			(cast window).aceEditor = editor;
			js.Syntax.code("{0}.$hxClasses = $hxClasses", window);
			js.Syntax.code("{0}.$gmedit = $hxClasses", window);
			//
			session = AceTools.cloneSession(q.session);
			editor.setSession(session);
			//
			var scrollTop = q.session.getScrollTop();
			if (scrollTop == session.getScrollTop()) {
				session.setScrollTop(scrollTop + 1);
			}
			//
			window.setTimeout(function() {
				var e = new CustomEvent("resize");
				e.initEvent("resize");
				window.dispatchEvent(e);
				session.setScrollTop(scrollTop);
			}, 1);
			//
			if (Electron.isAvailable()) {
				editor.commands.addCommand({
					name: "toggleDevTools",
					bindKey: {
						win: "ctrl-shift-i",
						mac: "cmd-shift-i",
					},
					exec: function(_) {
						electron.extern.BrowserWindow.getFocusedWindow().toggleDevTools();
					}
				});
			}
			editor.commands.addCommand({
				name: "saveFile",
				bindKey: {win: "Ctrl-S", mac: "Command-S"},
				exec: function(e) {
					var file = e.session.gmlFile;
					if (file != null && file.save()) {
						Browser.window.setTimeout(() -> {
							if (file.codeEditor.session.getUndoManager().isClean()) {
								e.session.getUndoManager().markClean();
							}
						});
					}
				}
			});
		};
		window.addEventListener("load", function() {
			ready();
		});
	}
	public function destroy() {
		try {
			window.close();
		} catch (x:Any) {
			
		}
	}
}