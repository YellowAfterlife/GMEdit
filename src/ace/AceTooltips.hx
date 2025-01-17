package ace;
import ace.extern.AceDelayedCall;
import ace.extern.AceMarker;
import ace.extern.AcePos;
import ace.extern.AceRange;
import ace.extern.AceSession;
import ace.extern.AceToken;
import ace.AceWrap;
import ace.extern.AceTokenIterator;
import ace.extern.AceTooltip;
import ace.AceStatusBar;
import file.kind.gml.KGmlScript;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlFuncDoc;
import gml.GmlGlobalVar;
import gml.GmlImports;
import gml.GmlLocals;
import gml.Project;
import synext.GmlExtLambda;
import tools.Dictionary;
import tools.JsTools;
import ui.Preferences;
import js.html.Console;
using tools.NativeString;

/**
 * Shows tooltips on mouseovering code
 * @author YellowAfterlife
 */
class AceTooltips {
	var ttip:AceTooltip;
	var text:String = null;
	var token:AceToken = null;
	var timeout:Int = null;
	var kbdc:AceDelayedCall;
	var marker:AceMarker = null;
	var markerSession:AceSession = null;
	//
	static var spriteThumbs:Dictionary<String> = new Dictionary();
	public static function resetCache():Void {
		spriteThumbs = new Dictionary();
	}
	
	public static var getDocAt_extra:String;
	public static function getDocAt(session:AceSession, pos:AcePos, token:AceToken) {
		var scope = session.gmlScopes.get(pos.row);
		var codeEditor = session.gmlEditor;
		var iter = new AceTokenIterator(session, pos.row, pos.column);
		//
		var feit = new AceTokenIterator(session, pos.row, pos.column);
		var funcEnd:AcePos;
		if (feit.stepForward() == null) {
			funcEnd = session.getEOF();
		} else funcEnd = feit.getCurrentTokenPosition();
		//
		var ctx:AceStatusBarDocSearch = {
			session: session, scope: scope,
			imports: codeEditor.imports[scope],
			lambdas: codeEditor.lambdas[scope],
			tk: token, doc: null, docs: null,
			iter: iter,
			exprStart: iter.getCurrentTokenPosition(),
			funcEnd: funcEnd,
		};
		var doc:GmlFuncDoc = null;
		if (AceStatusBar.getDocData(ctx)) {
			doc = ctx.doc;
			if (doc == null) {
				AceStatusBar.procDocImport(ctx);
				doc = ctx.doc;
			}
		}
		//
		if (ctx.typeText != null) {
			getDocAt_extra = ctx.typeText;
		} else if (ctx.type != null) {
			getDocAt_extra = "type " + ctx.type.toString();
		} else {
			getDocAt_extra = null;
		}
		return doc;
	}
	//
	function update(session:AceSession, pos:AcePos, token:AceToken) {
		var t = token.type;
		var v = token.value;
		var r:String = null;
		var extra:String = null;
		var z:Bool = false;
		//
		var doc:GmlFuncDoc = null;
		//
		if (AceStatusBar.canDocData.exists(t) || Std.is(session.gmlFile.kind, file.kind.KGml)) {
			doc = getDocAt(session, pos, token);
			extra = extra.nzcct("\n", getDocAt_extra);
			/*
			// the following doesn't work quite right,
			// have to figure out why it can get offset
			// (probably because of my changes to line count gutter width)
			if (marker != null) markerSession.removeMarker(marker);
			var to = ctx.funcEnd;
			var from = ctx.exprStart;
			//to = to.add(1, 0);
			//Console.log(from, to);
			marker = session.addMarker(AceRange.fromPair(from, to), "debugShowToken", "text");
			markerSession = session;
			*/
		}
		inline function calcRow(row:Int) {
			var showRow = row;
			var startRow = row + 1;
			var file = session.gmlFile;
			var isScript = JsTools.nca(file, (file.kind is KGmlScript));
			var checkRx = isScript ? GmlAPI.scopeResetRx : GmlAPI.scopeResetRxNF;
			if (GmlExternAPI.gmlResetOnDefine) while (--startRow >= 0) {
				if (checkRx.test(session.getLine(startRow))) {
					showRow -= startRow + 1;
					break;
				}
			}
			return showRow;
		}
		r = r.nzcct("\n", extra);
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
				var isRGB = false;
				var hex = switch (v.length) {
					case 8 if (v.startsWith("0x")): v.substring(2);
					case 7 if (v.charCodeAt(0) == "$".code): v.substring(1);
					case 7 if (v.charCodeAt(0) == "#".code): isRGB = true; v.substring(1);
					default: null;
				}
				if (hex != null) {
					r = isRGB ? "color:#" +hex : "color:0x" + hex;
					if (text != r) {
						text = r;
						var int = Std.parseInt("0x" + hex);
						var rgb = isRGB ? hex
							: hex.substr(4, 2) + hex.substr(2, 2) + hex.substr(0, 2);
						var rgbStr:String;
						if (isRGB) {
							rgbStr = ((int >> 16) & 0xff)
								+ ', ' + ((int >> 8) & 0xff)
								+ ', ' + (int & 0xff);
						} else {
							rgbStr = (int & 0xff)
								+ ', ' + ((int >> 8) & 0xff)
								+ ', ' + ((int >> 16) & 0xff);
						}
						ttip.setHtml('<span style="'
							+ 'display: inline-block;'
							+ 'background-color: #$rgb;'
							+ 'vertical-align: middle;'
							+ 'width: 0.8em;'
							+ 'height: 0.8em;'
						+ '"></span> RGB($rgbStr)');
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
							r = "Closes line " + (calcRow(row) + 1) + ": ";
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
							r = "Spans until line " + (calcRow(row) + 1);
							var rowText = session.getLine(row);
							var len = session.getLength();
							while (rowText != null && row < len && rowText.trimBoth().length <= 1) {
								rowText = session.getLine(++row);
							}
							if (rowText != null) r += ": " + rowText;
							break;
						};
					}
					tk = iter.stepForward();
				}
			};
			default: //r = t;
		}
		//
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
	function new(editor:AceWrap) {
		ttip = new AceTooltip(editor.container);
		var content = editor.container.querySelector(".ace_content");
		inline function show():Void {
			ttip.show();
		}
		inline function hide():Void {
			ttip.hide();
			if (marker != null) {
				markerSession.removeMarker(marker);
				markerSession = null;
				marker = null;
				Console.log("hid");
			}
		}
		inline function stop():Void {
			if (timeout != null) { Main.window.clearTimeout(timeout); timeout = null; }
			kbdc.cancel();
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
		editor.on("blur", function(_) {
			hide();
			stop();
		});
		editor.on("mousemove", function(ev:Dynamic) {
			var pc = Preferences.current;
			if (pc.tooltipKind == None) return;
			var t = pc.tooltipDelay;
			var pos:AcePos = ev.getDocumentPosition();
			pos.column++; // I wonder what's this all about
			if (t > 0) {
				//hide();
				stop();
				timeout = Main.window.setTimeout(function() {
					timeout = null;
					sync(pos, ev.x, ev.y);
				}, t);
			} else sync(pos, ev.x, ev.y);
		});
		//
		var lang = AceWrap.require("ace/lib/lang");
		kbdc = lang.delayedCall(function updateKeyboard() {
			var session = editor.session;
			var selection = session.selection;
			if (!selection.isEmpty()) return;
			var pos = selection.lead;
			var tk = session.getTokenAtPos(pos);
			if (tk != null) {
				if (tk != token) {
					token = tk;
					update(editor.session, pos, tk);
				}
				if (text != null) {
					var pp = editor.renderer.textToScreenCoordinates(pos.row, pos.column);
					ttip.setPosition(pp.pageX, pp.pageY + editor.renderer.lineHeight);
					show();
				} else hide();
			}
		});
		editor.on("keyboardActivity", function() {
			var t = Preferences.current.tooltipKeyboardDelay;
			if (t > 0) kbdc.schedule(t);
		});
	}
	public static function bind(editor:AceWrap) {
		editor.tooltipManager = new AceTooltips(editor);
	}
}
