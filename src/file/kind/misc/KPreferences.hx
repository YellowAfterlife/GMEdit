package file.kind.misc;
import gml.file.GmlFile.GmlFileNav;
import gml.file.GmlFile;
import editors.Editor;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class KPreferences extends FileKind {
	public static var inst = new KPreferences();
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new KPreferencesEditor(file);
	}
}
private class KPreferencesEditor extends Editor {
	public function new(file:GmlFile) {
		super(file);
		var el = Preferences.element;
		if (el == null) {
			el = Main.document.createDivElement();
			el.classList.add("popout-window");
			el.id = "preferences-editor";
			Preferences.element = el;
			Preferences.buildMain();
		}
		element = Preferences.element;
		Preferences.setMenu(Preferences.menuMain);
	}
}
