package file.kind.misc;
import gml.file.GmlFile.GmlFileNav;
import gml.file.GmlFile;
import gml.Project;
import editors.Editor;
import ui.project.ProjectProperties;

/**
 * ...
 * @author YellowAfterlife
 */
class KProjectProperties extends KPreferencesBase {
	public static var inst = new KProjectProperties();
	override public function init(file:GmlFile, data:Dynamic):Void {
		file.editor = new KProjectPropertiesEditor(file, data);
	}
}
class KProjectPropertiesEditor extends Editor {
	public var project:Project;
	public function new(file:GmlFile, pj:Project) {
		super(file);
		project = pj;
		if (pj.propertiesElement == null) {
			pj.propertiesElement = Main.document.createDivElement();
			pj.propertiesElement.classList.add("popout-window");
			pj.propertiesElement.classList.add("project-properties");
			ProjectProperties.build(pj, pj.propertiesElement);
		}
		element = pj.propertiesElement;
		/*if (el == null) {
			el = Main.document.createDivElement();
			el.classList.add("popout-window");
			el.id = "preferences-editor";
			project.propertiesElement = el;
			ProjectProperties.build(el);
		}
		element = el;*/
		//Preferences.setMenu(Preferences.menuMain);
	}
}
