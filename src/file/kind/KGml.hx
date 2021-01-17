package file.kind;
import gml.file.GmlFile.GmlFileNav;
import editors.EditCode;
import editors.Editor;
import electron.Dialog;
import js.lib.RegExp;
import parsers.*;
import synext.*;
import tools.NativeString;

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
	
	public function new() {
		super();
		modePath = "ace/mode/gml";
		indexOnSave = true;
	}
	
	override public function preproc(editor:EditCode, code:String):String {
		var onDisk = editor.file.path != null;
		if (onDisk && canLambda) code = GmlExtLambda.pre(editor, code);
		if (canMFunc) code = GmlExtMFunc.pre(editor, code);
		if (onDisk && canImport) code = GmlExtImport.pre(code, editor.file.path);
		if (canNullCoalescingOperator) code = GmlNullCoalescingOperator.pre(code);
		if (canNullCoalescingAssignment) code = GmlNullCoalescingAssignment.pre(code);
		if (canTemplateString) code = GmlExtTemplateStrings.pre(code);
		if (canHyper) code = GmlExtHyper.pre(code);
		return code;
	}
	
	override public function postproc(editor:EditCode, code:String):String {
		saveSessionChanged = false;
		var onDisk = editor.file.path != null;
		if (canHyper) code = GmlExtHyper.post(code);
		if (canTemplateString) code = GmlExtTemplateStrings.post(code);
		if (canNullCoalescingAssignment) code = GmlNullCoalescingAssignment.post(code);
		if (canNullCoalescingOperator) code = GmlNullCoalescingOperator.post(code);
		if (onDisk && canImport) {
			var pair = editor.postpImport(code);
			if (pair == null) return null;
			code = pair.val;
			if (pair.sessionChanged) saveSessionChanged = true;
		}
		if (canMFunc) {
			code = GmlExtMFunc.post(editor, code);
			if (code == null) {
				Dialog.showError("Can't process #mfunc:\n" + GmlExtMFunc.errorText);
				return null;
			}
		}
		if (onDisk && canLambda) {
			code = GmlExtLambda.post(editor, code);
			if (code == null) {
				Dialog.showError("Can't process #lambda:\n" + GmlExtLambda.errorText);
				return null;
			}
		}
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
			var rxDef = new RegExp("^(#define|#event|#moment|#target|function)[ \t]" + NativeString.escapeRx(nav.def) + "\\b");
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
	
	override public function index(path:String, content:String, main:String):Bool {
		var content_noCoroutines = content;
		content = GmlExtCoroutines.pre(content);
		//
		var out = new GmlSeekData(this);
		out.hasCoroutines = content != content_noCoroutines;
		out.main = main;
		var locals = new gml.GmlLocals();
		out.locals.set("", locals);
		GmlSeeker.runSyncImpl(path, content, main, out, locals, this);
		GmlSeeker.finish(path, out);
		return true;
	}
}
