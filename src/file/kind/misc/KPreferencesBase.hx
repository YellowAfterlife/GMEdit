package file.kind.misc;
import gml.file.GmlFile.GmlFileNav;
import editors.Editor;
import file.FileKind;
import js.html.Element;
import tools.JsTools;
using tools.HtmlTools;
using tools.NativeString;

/**
 * Parent for configuration file kinds
 * @author YellowAfterlife
 */
class KPreferencesBase extends FileKind {
	//
	override public function navigate(editor:Editor, nav:GmlFileNav):Bool {
		var ctr = editor.element;
		var target:Element = null;
		if (nav.def != null) {
			target = ctr.querySelector("#" + nav.def);
		} else if (nav.ctx != null) {
			var legends = ctr.querySelectorEls("legend");
			for (legend in legends) {
				if (legend.textContent == nav.ctx) {
					target = legend.parentElement;
					break;
				}
			}
		}
		if (target == null) return false;
		target.scrollIntoView();
		ctr.scrollTop -= 20;
		//HtmlTools.scrollIntoViewIfNeeded(target);
		return true;
	}
}