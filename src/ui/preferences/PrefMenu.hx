package ui.preferences;
import js.html.Element;
import ui.Preferences.*;
import electron.FileWrap;
import electron.Shell;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefMenu {
	public static function build(out:Element):Void {
		out.appendChild(Main.document.createTextNode("(note: you can click on section headers to collapse/expand them)"));
		PrefTheme.build(out);
		PrefCode.build(out);
		PrefNav.build(out);
		PrefLinter.build(out, null);
		PrefMagic.build(out);
		PrefApp.build(out);
		PrefBackups.build(out);
		PrefPlugins.build(out);
		if (electron.Electron.isAvailable()) {
			var gr = addGroup(out, "Other useful things"), el:Element;
			//
			el = addButton(gr, "GML dialects directory", function() {
				Shell.openItem(FileWrap.userPath + "/api");
			});
			addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/GML-dialects");
			//
			el = addButton(gr, "Reload GMEdit", function() {
				Main.document.location.reload();
			});
			el.title = "Required when adding themes/plugins/dialects";
		}
	}
}
