package ui.preferences;
import js.html.Element;
import js.html.FieldSetElement;
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
		var fs:FieldSetElement = addRadios(out, "Theme", current.theme, themeList, function(theme) {
			current.theme = theme;
			Theme.current = theme;
			save();
		});
		addGroupToggle(fs);
		fs.id = "pref-theme";
		var lg = fs.querySelector('legend');
		lg.appendChild(document.createTextNode(" ("));
		lg.append(createShellAnchor("https://github.com/GameMakerDiscord/GMEdit/wiki/Using-themes", "wiki"));
		if (FileSystem.canSync) {
			lg.appendChild(document.createTextNode("; "));
			lg.append(createShellAnchor(FileWrap.userPath + "/themes", "manage"));
		}
		lg.appendChild(document.createTextNode(")"));
	}
}
