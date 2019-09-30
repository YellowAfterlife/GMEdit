package ui.preferences;
import js.html.Element;
import ui.Preferences.*;
import gml.GmlVersion;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefBackups {
	public static function build(out:Element) {
		out = addGroup(out, "Backups");
		out.id = "pref-backups";
		addWiki(out, "https://github.com/GameMakerDiscord/GMEdit/wiki/Preferences#backups");
		var el:Element;
		//
		addText(out, "Values are numbers of backup copies per file.");
		for (v in GmlVersion.list) {
			var s = v.name;
			addIntInput(out, 'for `${v.label}` projects', current.backupCount[s], function(n) {
				current.backupCount[s] = n; save();
			});
		}
	}
}
