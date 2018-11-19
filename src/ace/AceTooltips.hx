package ace;
import Main.aceEditor;
import ace.extern.AcePos;
import ace.extern.AceSession;
import ace.extern.AceToken;
import ace.AceWrap;
import ace.extern.AceTokenIterator;
import ace.extern.AceTooltip;
import ace.AceStatusBar;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlFuncDoc;
import gml.GmlGlobalVar;
import gml.GmlImports;
import gml.GmlLocals;
import gml.Project;
import parsers.GmlExtLambda;
import ui.Preferences;
using tools.NativeString;

/**
 * Shows tooltips on mouseovering code
 * @author YellowAfterlife
 */
class AceTooltips {
	static var ttip:AceTooltip;
	static var text:String = null;
	static function update(session:AceSession, pos:AcePos, token:AceToken) {
		var t = token.type;
		var v = token.value;
		var r:String = null;
		//
		var doc:GmlFuncDoc = null;
		var iter:AceTokenIterator;
		//
		if (AceStatusBar.canDocData[t]) {
			var scope = gml.GmlScopes.get(pos.row);
			var ctx:AceStatusBarDocSearch = {
				iter: new AceTokenIterator(session, pos.row, pos.column),
				tk: token, doc: null, docs: null,
				imports: GmlImports.currentMap[scope],
				lambdas: GmlExtLambda.currentMap[scope],
			};
			if (AceStatusBar.getDocData(ctx)) {
				doc = ctx.doc;
				if (doc == null) {
					AceStatusBar.procDocImport(ctx);
					doc = ctx.doc;
				}
			}
		}
		if (doc == null) switch (t) {
			case "enumfield": {
				var iter = new AceTokenIterator(session, pos.row, pos.column);
				var et:GmlEnum = null;
				var tk = iter.stepBackward();
				if (tk != null && tk.type == "text") tk = iter.stepBackward();
				if (tk != null && tk.value == ".") { // Enum.field, local.field
					tk = iter.stepBackward();
					if (tk != null && tk.type == "text") tk = iter.stepBackward();
					if (tk != null) switch (tk.type) {
						case "enum": et = GmlAPI.gmlEnums[tk.value];
						case "local", "sublocal": {
							// does the user *want* to see "4" when mouseovering some.field?
						};
					}
				} else while (tk != null) {
					if (tk.type == "enum") {
						et = GmlAPI.gmlEnums[tk.value];
						break;
					}
					tk = iter.stepBackward();
				}
				if (et != null) {
					var ef = et.compMap[v];
					if (ef != null) r = ef.doc;
				}
			};
			case "macro": {
				var mc = GmlAPI.gmlMacros[v];
				if (mc != null) r = mc.expr;
			};
			case "extmacro": {
				var comp = GmlAPI.extCompMap[v];
				if (comp != null) r = comp.doc;
			};
			default: //r = t;
		}
		if (doc != null) r = doc.getAcText();
		switch (t) {
			case "globalvar": r = (r == null) ? "[globalvar]" : "[globalvar] " + r;
		}
		if (r == "") r = null;
		if (text != r) {
			text = r;
			if (r != null) ttip.setText(r);
		}
	}
	public static function init() {
		var token:AceToken = null;
		ttip = new AceTooltip(aceEditor.container);
		var visible = false;
		var timeout:Int = null;
		var content = aceEditor.container.querySelector(".ace_content");
		inline function show():Void {
			if (!visible) { visible = true; ttip.show(); }
		}
		inline function hide():Void {
			if (visible) { visible = false; ttip.hide(); }
		}
		inline function stop():Void {
			if (timeout != null) { Main.window.clearTimeout(timeout); timeout = null; }
		}
		function sync(pos:AcePos, x:Float, y:Float) {
			var line = aceEditor.session.getLine(pos.row);
			var eol = line == null || pos.column >= line.length;
			var tk = eol ? null : aceEditor.session.getTokenAtPos(pos);
			if (tk != null) {
				if (tk != token) {
					token = tk;
					update(aceEditor.session, pos, tk);
				}
				if (text != null) {
					ttip.setPosition(x, y + 16);
					show();
				} else hide();
			} else hide();
		}
		content.addEventListener("mouseout", function(ev:Dynamic) {
			Main.console.log(ev);
			hide();
			stop();
		});
		aceEditor.on("mousedown", function(_) {
			hide();
		});
		aceEditor.on("mousemove", function(ev:Dynamic) {
			var pc = Preferences.current;
			if (pc.tooltipKind == None) return;
			var t = pc.tooltipDelay;
			var pos:AcePos = ev.getDocumentPosition();
			if (t > 0) {
				//hide();
				stop();
				timeout = Main.window.setTimeout(function() {
					timeout = null;
					sync(pos, ev.x, ev.y);
				}, t);
			} else sync(pos, ev.x, ev.y);
		});
	}
}
