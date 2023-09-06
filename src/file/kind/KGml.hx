package file.kind;
import ace.extern.AceAutoCompleteItems;
import gml.file.GmlFile.GmlFileNav;
import editors.EditCode;
import editors.Editor;
import electron.Dialog;
import js.lib.RegExp;
import parsers.*;
import synext.*;
import tools.CharCode;
import tools.JsTools;
import synext.GmlExtCoroutines;
using tools.NativeString;

/**
 * A parent for any kinds containing GML code.
 * @author YellowAfterlife
 */
class KGml extends KCode {
	public static var inst:KGml = new KGml();
	
	/// Whether #import magic is supported for this kind
	public var canImport:Bool = true;
	
	/// Whether #lambda magic is supported for this kind
	public var canLambda:Bool = true;
	
	/// Whether #hyper magic is supported for this kind
	public var canHyper:Bool = true;
	
	/// Whether `..${expr}..` magic is supported for this kind
	public var canTemplateString:Bool = true;
	
	/** Whether `a ??= b` is supported for this kind */
	public var canNullCoalescingAssignment:Bool = true;
	
	/** Whether `a ?? b` is supported for this kind */
	public var canNullCoalescingOperator:Bool = true;
	
	/// Whether #mfunc magic is supported for this kind
	public var canMFunc:Bool = true;
	
	/// Whether #define will add scripts to auto-completion
	public var canDefineComp:Bool = false;
	
	/** Whether it makes sense to check syntax in this file type */
	public var canSyntaxCheck:Bool = true;
	
	/**
	 * Whether editor session had been modified during the current save operation.
	 * We need this because trying to modify it multiple times can be destructive.
	 */
	public var saveSessionChanged:Bool;
	
	/**
	 * NB! Syntax extensions are applied in "forward" order on open/preproc
	 * and in backwards order on save/postproc.
	 */
	public static var syntaxExtensions:Array<SyntaxExtension> = null;
	
	public static function initSyntaxExtensions() {
		syntaxExtensions = [
			// GmlExtCoroutines.inst, // done in KGmlScript
			GmlExtLambda.inst,
			GmlExtMFunc.inst,
			GmlExtImport.inst,
			GmlNullCoalescingOperator.inst,
			GmlNullCoalescingAssignment.inst,
			GmlExtArrowFunctions.inst,
			GmlExtTemplateStrings.inst,
			GmlExtCast.inst,
			GmlExtHashColorLiterals.inst,
			GmlExtHyper.inst,
			// GmlExtArgs.inst, // also done in KGmlScript AND it's done out of order
		];
	}
	
	public function new() {
		super();
		modePath = "ace/mode/gml";
		indexOnSave = true;
	}
	
	override public function preproc(editor:EditCode, code:String):String {
		code = SyntaxExtension.preprocArray(editor, code, syntaxExtensions);
		return code != null ? code : "";
	}
	
	override public function postproc(editor:EditCode, code:String):String {
		saveSessionChanged = false;
		
		code = SyntaxExtension.postprocArray(editor, code, syntaxExtensions);
		return code;
	}
	
	override public function navigate(editor:Editor, nav:GmlFileNav):Bool {
		var session = (cast editor:EditCode).session;
		var len = session.getLength();
		//
		var found = false;
		var row = 0, col = 0;
		var i:Int, s:String;
		if (nav.def != null) {
			var rxDef = new RegExp("^(#define|#event|#moment|#target|function)[ \t]+" + NativeString.escapeRx(nav.def) + "\\b");
			i = 0;
			while (i < len) {
				s = session.getLine(i);
				if (rxDef.test(s)) {
					row = i;
					col = s.length;
					found = true;
					break;
				} else i += 1;
			}
		}
		//
		var ctx = nav.ctx;
		if (ctx != null) {
			var rxCtx = new RegExp(NativeString.escapeRx(ctx));
			var rxEof = new RegExp("^(#define|#event|#moment|#target)");
			i = row;
			if (nav.ctxAfter && nav.pos != null) i += nav.pos.row;
			var start = found ? i : -1;
			while (i < len) {
				s = session.getLine(i);
				if (i != start && rxEof.test(s)) break;
				var vals = rxCtx.exec(s);
				if (vals != null) {
					row = i;
					col = vals.index;
					found = true;
					break;
				} else i += 1;
			}
		}
		//
		var pos = nav.pos;
		if (pos != null) {
			if (ctx == null && nav.def != null) {
				col = 0;
				row += 1;
			}
			if (!found || !nav.ctxAfter) {
				row += pos.row;
				col += pos.column;
				found = true;
			}
		}
		if (found) {
			if (nav.showAtTop) {
				Main.aceEditor.scrollToLine(row);
				// so, scrollToLine doesn't update state immediately, and gotoLine tries to
				// scroll it with center==true instead, so we have to do this little dance
				// where we temporarily strip out scrollToLine and then put it back in.
				var f = Main.aceEditor.scrollToLine;
				var z = untyped Main.aceEditor.hasOwnProperty("scrollToLine");
				untyped Main.aceEditor.scrollToLine = function() {};
				Main.aceEditor.gotoLine0(row, col);
				if (z) {
					untyped Main.aceEditor.scrollToLine = f;
				} else js.Syntax.code("delete {0}.scrollToLine", Main.aceEditor);
			} else Main.aceEditor.gotoLine0(row, col);
		}
		return found;
	}
	
	override public function index(path:String, content:String, main:String, sync:Bool):Bool {
		var content_noCoroutines = content;
		content = GmlExtCoroutines.pre(content);
		
		var out = new GmlSeekData(this);
		//
		out.hasCoroutines = content != content_noCoroutines;
		var crResult = GmlExtCoroutines.result;
		if (crResult != null) {
			out.yieldScripts = crResult.yieldScripts;
			out.coroutineMode = crResult.mode;
			if ((crResult.mode:GmlExtCoroutineMode) == Constructor) {
				for (scr in out.yieldScripts) {
					// we are indexing the original code so that the user sees their variables
					// and such, but we do also need coroutine-constructor information
					// for type checking and auto-completion
					var ctr = GmlExtCoroutines.constructorFor(scr);
					content += "\n/// @hint {any} " + ctr + ":result";
					content += "\n/// @hint {bool} " + ctr + ":next()";
				}
			}
		}
		//
		out.main = main;
		var locals = new gml.GmlLocals();
		out.locals.set("", locals);
		GmlSeeker.runSyncImpl(path, content, main, out, locals, this);
		GmlSeeker.finish(path, out);
		return true;
	}
	
	override public function gatherGotoTargets(editor:EditCode):AceAutoCompleteItems {
		var items:AceAutoCompleteItems = [];
		var code = editor.session.getValue();
		var q = new GmlReader(code);
		var curlyDepth = 0;
		var lineNumber = 0;
		var version = gml.Project.current.version;
		var hasRegions = true;
		function add(name:String, meta:String) {
			items.push({ value: "" + lineNumber, caption: name, meta: meta });
		}
		while (q.loop) {
			var at = q.pos;
			var c:CharCode = q.read();
			switch (c) {
				case "\n".code: lineNumber++;
				case "{".code: curlyDepth++;
				case "}".code: curlyDepth--;
				case "/".code: switch (q.peek()) {
					case "/".code:
						q.skip();
						if (q.skipIfEquals("#".code)) {
							var kind:String = if (q.skipIfIdentEquals("region")) {
								"region";
							} else if (q.skipIfIdentEquals("mark")) {
								"mark";
							} else null;
							if (kind != null) {
								at = q.pos;
								q.skipLine();
								var txt = q.substring(at, q.pos).trimBoth();
								if (txt != "") add(txt, kind);
							}
						}
						q.skipLine();
					case "*".code: q.skip(); lineNumber += q.skipComment();
				};
				case '"'.code, "'".code, "@".code, "`".code: lineNumber += q.skipStringAuto(c, version);
				case "$".code if (q.isDqTplStart(version)): lineNumber += q.skipDqTplString(version);
				case "#".code: {
					if (q.skipIfIdentEquals("region")) {
						at = q.pos;
						q.skipLine();
						var txt = q.substring(at, q.pos).trimBoth();
						if (txt != "") add(txt, "region");
					} else if (q.skipIfIdentEquals("endregion")) {
						q.skipLine();
					} else if (at == 0 || q.get(at - 1) == "\n".code) {
						var newCtx = q.readContextName(null);
						if (newCtx != null) {
							var meta = switch (q.get(at + 1)) {
								case "d".code: "function";
								case "e".code: "event";
								case "m".code: "moment";
								default: null;
							}
							add(newCtx, meta);
						}
					}
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					if (c == "f".code && curlyDepth == 0
						&& q.pos - at == JsTools.clen("function")
						&& q.get(q.pos - 1) == "n".code
						&& q.substring(at, q.pos) == "function"
					) {
						lineNumber += q.skipSpaces1();
						var fname = q.readIdent();
						if (fname != null) add(fname, "function");
					}
				};
			}
		}
		return items;
	}
}
