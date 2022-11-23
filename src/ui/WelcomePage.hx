package ui;
import ace.AceWrap;
import ace.extern.*;
import electron.Electron;
import electron.FileSystem;
import gml.file.GmlFile;
import file.kind.misc.KPlain;
import file.kind.gml.KGmlScript;
import tools.macros.SynSugar;

/**
 * What you see when you boot up GMEdit
 * @author YellowAfterlife
 */
class WelcomePage {
	public static var file:GmlFile;
	public static function init(e:AceEditor) {
		var session:AceSession;
		#if gmedit.mini
			file = new GmlFile("WelcomePage", null, KPlain.inst, "");
			GmlFile.current = file;
			session = file.codeEditor.session;
			session.setValue(lwText);
		#elseif gmedit.live
			file = new GmlFile("WelcomePage", null, ui.liveweb.KLiveWeb.inst, "");
			GmlFile.current = file;
			session = file.codeEditor.session;
			session.setValue(lwText);
		#else
			file = new GmlFile("WelcomePage", null, KPlain.inst, "");
			GmlFile.current = file;
			session = file.codeEditor.session;
			var rel = Electron != null ? "misc/welcome.txt" : "misc/welcome-web.txt";
			FileSystem.readTextFile(Main.relPath(rel), function(err, text) {
				text = tools.NativeString.replaceExt(text, "%%VERSION%%", ace.AceMacro.timestamp());
				session.setValue(text);
			});
		#end
		return session;
	}
	#if gmedit.mini
	public static var lwText:String = SynSugar.xmls(<txt>
		// Double-click the tab bar or use the menu to add a tab.
	</txt>);
	public static var lwCode:String = SynSugar.xmls(<gml>
		show_debug_message("hi!");
		return "OK";
	</gml>);
	#elseif gmedit.live
	public static var lwText:String = StringTools.replace(SynSugar.xmls(<gml>
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

		$define step
		// step event code
		frame += delta_time/1000000;

		$define draw
		// draw event code
		scr_show("hi!");

		$define scr_show
		// define scripts like this
		draw_text(10, 10 + sin(frame / 0.7) * 3, argument0);
	</gml>), "$define", "#define");
	#end
}
