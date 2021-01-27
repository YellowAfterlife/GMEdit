package ui;
import ace.AceWrap;
import ace.extern.*;
import electron.FileSystem;
import gml.file.GmlFile;
import file.kind.misc.KPlain;
import file.kind.gml.KGmlScript;
import tools.macros.SynSugar;

/**
 * ...
 * @author YellowAfterlife
 */
class WelcomePage {
	public static var file:GmlFile;
	public static function init(e:AceEditor) {
		var session:AceSession;
		#if lwedit
			file = new GmlFile("WelcomePage", null, KGmlScript.inst, "");
			GmlFile.current = file;
			session = file.codeEditor.session;
			session.setValue(lwText);
		#else
			file = new GmlFile("WelcomePage", null, KPlain.inst, "");
			GmlFile.current = file;
			session = file.codeEditor.session;
			FileSystem.readTextFile(Main.relPath("misc/welcome.txt"), function(err, text) {
				text = tools.NativeString.replaceExt(text, "%%VERSION%%", ace.AceMacro.timestamp());
				session.setValue(text);
			});
		#end
		return session;
	}
	#if lwedit
	public static var lwText:String = SynSugar.xmls(<gml>
		/*
		Hello!

		Double-click the top panel to add a code tab.
		Ctrl+Enter or F5 to run your code.

		Also check out Help in the main menu.

		Try copying the following to a new code tab for a test:
		*/
		// init
		trace("hi!");
		frame = 0;

		#define step
		// step event code
		frame += delta_time/1000000;

		#define draw
		// draw event code
		scr_show("hi!");

		#define scr_show
		// define scripts like this
		draw_text(10, 10 + sin(frame / 0.7) * 3, argument0);
	</gml>);
	#end
}
