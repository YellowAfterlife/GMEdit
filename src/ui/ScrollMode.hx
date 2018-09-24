package ui;
import Main.*;
import ace.AceWrap;
import ace.extern.*;
import js.html.Element;
import js.html.MouseEvent;

/**
 * If you consider, this is a pretty big pile of hacks as for just
 * being able to middle click to enter scroll mode on the editor.
 * @author YellowAfterlife
 */
class ScrollMode {
	private static var scrollbar:Element;
	private static var container:Element;
	private static var scrollbarWidth:String;
	private static var scrollbarWidthInt:Int;
	private static var scrollWait:Bool = false;
	public static function mousedown(e:MouseEvent) {
		// if a non-middle-button is clicked outside the scrollbar area,
		if (e.button != 1 && e.layerX < scrollbar.offsetWidth - scrollbarWidthInt) {
			// revert scrollbar to normal size and not touch it till it's released,
			scrollbar.style.width = scrollbarWidth;
			scrollbar.style.cursor = "";
			scrollWait = true;
			// and forward the event to Ace:
			var e1 = new MouseEvent(e.type, cast e);
			container.querySelector('.ace_scroller').dispatchEvent(e1);
			function fn(e:MouseEvent) {
				scrollWait = false;
				window.removeEventListener("mouseup", fn);
			}
			window.addEventListener("mouseup", fn);
		}
	}
	public static function mousemove(e:MouseEvent) {
		if (scrollWait) return;
		var sb:Element = aceEditor.renderer.scrollBar.element;
		var pos:AcePos = aceEditor.renderer.screenToTextCoordinates(e.clientX, e.clientY);
		var line = aceEditor.session.getLine(pos.row);
		var eol = line == null || pos.column >= line.length;
		if (eol) {
			// if we're past end of line, stretch the scrollbar container so that it can
			// absorb the middle click to start scroll mode
			sb.style.width = "100%";
			// (and show text cursor if it's over the text area)
			sb.style.cursor = e.layerX < scrollbar.offsetWidth - scrollbarWidthInt ? "text" : "";
		} else {
			// otherwise, revert to normal behaviour
			sb.style.width = scrollbarWidth;
			sb.style.cursor = "";
		}
	}
	public static function init() {
		try {
			new MouseEvent("mousedown");
		} catch (_:Dynamic) return;
		container = aceEditor.container;
		scrollbar = aceEditor.renderer.scrollBar.element;
		scrollbarWidth = scrollbar.style.width;
		scrollbarWidthInt = untyped parseInt(scrollbarWidth);
		scrollbar.addEventListener("mousedown", mousedown);
		container.addEventListener("mousemove", mousemove);
	}
}
