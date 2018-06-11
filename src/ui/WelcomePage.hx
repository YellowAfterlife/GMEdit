package ui;
import ace.AceWrap;
import electron.FileSystem;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class WelcomePage {
	public static var file:GmlFile;
	public static function init(e:AceEditor) {
		file = new GmlFile("WelcomePage", null, Plain, "");
		GmlFile.current = file;
		var session = (cast file.editor:editors.EditCode).session;
		FileSystem.readTextFile(Main.relPath("misc/welcome.txt"), function(err, text) {
			text = tools.NativeString.replaceExt(text, "%%VERSION%%", ace.AceMacro.timestamp());
			session.setValue(text);
		});
		return session;
	}
}
