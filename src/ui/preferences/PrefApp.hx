package ui.preferences;
import electron.Electron;
import electron.IPC;
import js.html.Element;
import ui.Preferences.*;
import gml.Project;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefApp {
	public static function build(out:Element) {
		if (Electron == null) return;
		out = addGroup(out, "Application");
		addIntInput(out, "Default window width", current.app.windowWidth, function(v) {
			current.app.windowWidth = v;
			IPC.send('resize-window', v, null);
			save();
		});
		addIntInput(out, "Default window height", current.app.windowHeight, function(v) {
			current.app.windowHeight = v;
			IPC.send('resize-window', null, v);
			save();
		});
		addCheckbox(out, "Use native window border (requires restart)", current.app.windowFrame, function(v) {
			current.app.windowFrame = v;
			save();
		});
	}
}