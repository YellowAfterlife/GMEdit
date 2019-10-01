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
		PrefTheme.build(out);
		PrefMagic.build(out);
		PrefCode.build(out);
		PrefLinter.build(out, null);
		PrefNav.build(out);
		PrefBackups.build(out);
		if (electron.Electron.isAvailable()) {
			var gr = addGroup(out, "Other useful things"), el:Element;
			//
			el = addButton(gr, "Plugins directory", function() {
				Shell.openExternal(FileWrap.userPath + "/plugins");
			});
			addWiki(el, "https://github.com/GameMakerDiscord/GMEdit/wiki/Using-plugins");
			//
			el = addButton(gr, "GML dialects directory", function() {
				Shell.openExternal(FileWrap.userPath + "/api");
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
