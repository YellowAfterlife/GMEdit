package ace;
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
import tools.Dictionary;
import ui.Preferences;
using tools.NativeString;

/**
 * Shows tooltips on mouseovering code
 * @author YellowAfterlife
 */
class AceTooltips {
	static var ttip:AceTooltip;
	static var text:String = null;
	static var spriteThumbs:Dictionary<String> = new Dictionary();
	public static function resetCache():Void {
		spriteThumbs = new Dictionary();
	}
	static function update(session:AceSession, pos:AcePos, token:AceToken) {
		var t = token.type;
		var v = token.value;
		var r:String = null;
		var z:Bool = false;
		//
		var doc:GmlFuncDoc = null;
		var iter:AceTokenIterator;
		//
		if (AceStatusBar.canDocData[t]) {
			var scope = session.gmlScopes.get(pos.row);
			var codeEditor = gml.file.GmlFile.current.codeEditor;
			var ctx:AceStatusBarDocSearch = {
				iter: new AceTokenIterator(session, pos.row, pos.column),
				tk: token, doc: null, docs: null,
				imports: codeEditor.imports[scope],
				lambdas: codeEditor.lambdas[scope],
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
			case "numeric": {
				var bgr:String;
				if (v.length == 8 && v.startsWith("0x")) {
					bgr = v.substring(2);
				} else if (v.length == 7 && v.charCodeAt(0) == "$".code) {
					bgr = v.substring(1);
				} else bgr = null;
				if (bgr != null) {
					r = "color:0x" + bgr;
					if (text != r) {
						text = r;
						var bit = Std.parseInt("0x" + bgr);
						var rgb = bgr.substr(4, 2) + bgr.substr(2, 2) + bgr.substr(0, 2);
						ttip.setHtml('<span style="'
							+ 'display: inline-block;'
							+ 'background-color: #$rgb;'
							+ 'vertical-align: middle;'
							+ 'width: 0.8em;'
							+ 'height: 0.8em;'
						+ '"></span> (' + (bit & 0xff)
							+ ', ' + ((bit >> 8) & 0xff)
							+ ', ' + ((bit >> 16) & 0xff)
						+ ')');
					}
				}
			};
			case "asset.sprite": {
				r = "sprite:" + v;
				if (text != r) {
					text = r;
					var th:String;
					if (spriteThumbs.exists(v)) {
						th = spriteThumbs[v];
					} else {
						th = Project.current.getSpriteURL(v);
						th = '<img src="' + NativeString.escapeProp(th)
							+ '" style="max-width:64px;max-height:64px">';
						spriteThumbs.set(v, th);
					}
					ttip.setHtml(th);
				}
				return;
			};
			case "curly.paren.rparen": {
				var iter = new AceTokenIterator(session, pos.row, pos.column);
				var depth = 1;
				var tk = iter.stepBackward();
				while (tk != null) {
					switch (tk.type) {
						case "curly.paren.rparen": depth++;
						case "curly.paren.lparen": if (--depth <= 0) {
							var row = iter.getCurrentTokenRow();
							r = "Closes line " + (row + 1) + ": ";
							var rowText = session.getLine(row);
							while (row > 0 && rowText.trimBoth().length <= 1) rowText = session.getLine(--row);
							r += rowText;
							break;
						};
					}
					tk = iter.stepBackward();
				}
			};
			case "curly.paren.lparen": {
				var iter = new AceTokenIterator(session, pos.row, pos.column);
				var depth = 1;
				var tk = iter.stepForward();
				while (tk != null) {
					switch (tk.type) {
						case "curly.paren.lparen": depth++;
						case "curly.paren.rparen": if (--depth <= 0) {
							var row = iter.getCurrentTokenRow();
							r = "Spans until line " + (row + 1);
							var rowText = session.getLine(row);
							while (rowText != null && rowText.trimBoth().length <= 1) rowText = session.getLine(++row);
							if (rowText != null) r += ": " + rowText;
							break;
						};
					}
					tk = iter.stepForward();
				}
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
			if (r != null && !z) ttip.setText(r);
		}
	}
	public static function bind(editor:AceWrap) {
		var token:AceToken = null;
		ttip = new AceTooltip(editor.container);
		var visible = false;
		var timeout:Int = null;
		var content = editor.container.querySelector(".ace_content");
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
			var line = editor.session.getLine(pos.row);
			var eol = line == null || pos.column >= line.length;
			var tk = eol ? null : editor.session.getTokenAtPos(pos);
			if (tk != null) {
				if (tk != token) {
					token = tk;
					update(editor.session, pos, tk);
				}
				if (text != null) {
					ttip.setPosition(x, y + 16);
					show();
				} else hide();
			} else hide();
		}
		content.addEventListener("mouseout", function(ev:Dynamic) {
			hide();
			stop();
		});
		editor.on("mousedown", function(_) {
			hide();
		});
		editor.on("mousemove", function(ev:Dynamic) {
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
