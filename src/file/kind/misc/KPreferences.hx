package file.kind.misc;
import ui.ChromeTabs.ChromeTab;
import gml.file.GmlFile.GmlFileNav;
import gml.file.GmlFile;
import editors.Editor;
import gml.project.ProjectState.ProjectTabState;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class KPreferences extends KPreferencesBase {
	public static var inst = new KPreferences();
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new KPreferencesEditor(file);
	}
	
	public static inline var tabStateKind = "user-preferences";
	override public function saveTabState(tab:ChromeTab):ProjectTabState {
		return { kind: tabStateKind, data: { top: tab.gmlFile.editor.element.scrollTop } };
	}
	public static function loadTabState(tabState:ProjectTabState):GmlFile {
		if (tabState.kind != tabStateKind) return null;
		var file = Preferences.open();
		file.editor.element.scrollTop = tabState.data.top;
		return file;
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
