package file.kind.misc;
import editors.EditCode;
import gml.file.GmlFile.GmlFileNav;
import js.RegExp;
import tools.NativeString;

import editors.Editor;
import file.kind.KCode;

/**
 * ...
 * @author YellowAfterlife
 */
class KMarkdown extends KCode {
	public var isDocMd:Bool;
	public function new(dmd:Bool) {
		super();
		isDocMd = dmd;
		modePath = "ace/mode/markdown";
	}
	override public function navigate(editor:Editor, nav:GmlFileNav):Bool {
		var session = (cast editor:EditCode).session;
		var len = session.getLength();
		//
		var found = false;
		var row = 0, col = 0;
		var i:Int, s:String;
		var defIndent:String = null;
		if (nav.def != null) {
			var rxDef = isDocMd
				? new RegExp("^([ \t]*)#\\[" + NativeString.escapeRx(nav.def) + "\\]")
				: new RegExp("^[ \t]*#+[ \t]*" + NativeString.escapeRx(nav.def) + "[ \t]*$");
			i = 0;
			while (i < len) {
				s = session.getLine(i);
				var mt = rxDef.exec(s);
				if (mt != null) {
					row = i;
					col = s.length;
					found = true;
					if (isDocMd) defIndent = mt[1];
					break;
				} else i += 1;
			}
		}
		//
		var ctx = nav.ctx;
		if (ctx != null) {
			var rxCtx = new RegExp(NativeString.escapeRx(ctx));
			var rxEof = defIndent != null ? new RegExp('^$defIndent}') : null;
			i = row;
			if (nav.ctxAfter && nav.pos != null) i += nav.pos.row;
			var start = found ? i : -1;
			while (i < len) {
				s = session.getLine(i);
				if (i != start && rxEof != null && rxEof.test(s)) break;
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
			if (nav.showAtTop) Main.aceEditor.scrollToLine(row);
			Main.aceEditor.gotoLine0(row, col);
		}
		return found;
	}
}
