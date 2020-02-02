package ui.preferences;
import js.html.Element;
import ui.Preferences.*;
import Main.document;
import electron.FileSystem;
import electron.FileWrap;
import haxe.io.Path;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefTheme {
	public static function build(out:Element):Void {
		var themeList = ["default"];
		if (!FileSystem.canSync) {
			themeList.push("dark");
			themeList.push("gms2");
		} else {
			for (dir in [
				Main.relPath(Theme.path),
				FileWrap.userPath + "/themes" 
			]) if (FileSystem.existsSync(dir)
			) for (name in FileSystem.readdirSync(dir)) {
				if (name == "default") continue;
				var full = Path.join([dir, name, "config.json"]);
				if (FileSystem.existsSync(full)) themeList.push(name);
			}
		}
		var el:Element = addRadios(out, "Theme", current.theme, themeList, function(theme) {
			current.theme = theme;
			Theme.current = theme;
			save();
		});
		el.id = "pref-theme";
		el = el.querySelector('legend');
		el.appendChild(document.createTextNode(" ("));
		el.append(createShellAnchor("https://github.com/GameMakerDiscord/GMEdit/wiki/Using-themes", "wiki"));
		if (FileSystem.canSync) {
			el.appendChild(document.createTextNode("; "));
			el.append(createShellAnchor(FileWrap.userPath + "/themes", "manage"));
		}
		el.appendChild(document.createTextNode(")"));
	}
}
