package ui;
import ace.AceWrap;
import electron.FileSystem;

/**
 * ...
 * @author YellowAfterlife
 */
class WelcomePage {
	public static var session:AceSession;
	public static function init(e:AceEditor) {
		session = new AceSession("", "");
		Preferences.hookSetOption(session);
		session.setUndoManager(new AceUndoManager());
		FileSystem.readTextFile(Main.relPath("misc/welcome.txt"), function(err, text) {
			text = tools.NativeString.replaceExt(text, "%%VERSION%%", ace.AceMacro.timestamp());
			session.setValue(text);
		});
		return session;
	}
}
