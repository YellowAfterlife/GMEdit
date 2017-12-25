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
		var text = FileSystem.readTextFileSync(Main.relPath("misc/welcome.txt"));
		text = tools.NativeString.replaceExt(text, "%%VERSION%%", ace.AceMacro.timestamp());
		session = new AceSession(text, "");
		session.setUndoManager(new AceUndoManager());
		return session;
	}
}
