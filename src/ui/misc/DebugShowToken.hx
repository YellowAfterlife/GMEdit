package ui.misc;
import ace.AceWrap;
import ace.extern.AceMarker;
import ace.extern.AcePos;
import ace.extern.AceRange;
import haxe.Json;

/**
 * ...
 * @author YellowAfterlife
 */
class DebugShowToken {
	public static function initEditor(editor:AceWrap) {
		var mki:AceMarker = null;
		function handleHover(ev:Dynamic) {
			var sb = editor.statusBar;
			if (sb == null) return;
			// ev.getDocumentPosition() is inaccurate for some reason?
			var pos:AcePos = editor.renderer.screenToTextCoordinates(ev.clientX, ev.clientY);
			pos.column++;
			if (mki != null) {
				editor.session.removeMarker(mki);
				mki = null;
			}
			var tk = editor.session.getTokenAtPos(pos);
			if (tk == null) {
				sb.setText(pos + " state: " + haxe.Json.stringify(editor.session.getState(pos.row)));
				return;
			}
			pos.column = tk.start;
			mki = editor.session.addMarker(AceRange.fromTokenPos(tk, pos), "debugShowToken", "text");
			//
			sb.setText(pos + " token: " + haxe.Json.stringify(tk));
		}
		var enabled = false;
		function toggle() {
			enabled = !enabled;
			if (enabled) {
				editor.on("mousemove", handleHover);
			} else {
				editor.off("mousemove", handleHover);
				if (mki != null) {
					editor.session.removeMarker(mki);
					mki = null;
				}
			}
		}
		(editor:Dynamic).debugShowToken = toggle;
		//toggle();
	}
}