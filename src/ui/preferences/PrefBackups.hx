package ui.preferences;
import js.html.Element;
import ui.Preferences.*;

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
		addIntInput(out, "for GMS1 projects", current.backupCount.v1, function(n) {
			current.backupCount.v1 = n; save();
		});
		addIntInput(out, "for GMS2 projects", current.backupCount.v2, function(n) {
			current.backupCount.v2 = n; save();
		});
		addIntInput(out, "for other projects", current.backupCount.live, function(n) {
			current.backupCount.live = n; save();
		});
	}
}
