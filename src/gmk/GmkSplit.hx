package gmk;
import electron.Dialog;
import electron.Electron;
import electron.FileSystem;
import electron.Shell;
import gml.Project;
import haxe.io.Path;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkSplit {
	public static function proc(gmkPath:String) {
		//Project.open(path);
		var pref = Preferences.current;
		var gmkSplitPath = pref.gmkSplitPath;
		var gmkExt = Path.extension(gmkPath);
		if (gmkSplitPath == "" || gmkSplitPath == null) {
			if (Electron == null) {
				Dialog.showError("A web version of GMEdit cannot do anything with GM≤8.1 files.");
				return;
			}
			switch (Dialog.showMessageBox({
				message: "GMEdit cannot natively open GM≤8.1 files,"
					+ " but it could call gmk-splitter to convert them to a format that it can open."
					+ "\nWould you like to provide a path to gmk-splitter?"
					+ "\n\nYou can always change the path under Preferences - Navigation",
				buttons: [
					"Browse for gmk-splitter",
					"Open gmk-splitter homepage",
					"Do nothing",
				],
			})) {
				case 0: {
					Dialog.showOpenDialog({
						filters: [new DialogFilter("Executable files (*.exe; *.jar)", ["exe", "jar"])]
					}, function(paths) {
						var path = paths[0];
						if (path == null) return;
						Preferences.current.gmkSplitPath = path;
						Preferences.save();
						proc(gmkPath);
					});
				};
				case 1: {
					Shell.openExternal("http://medo42.github.io/Gmk-Splitter/");
					proc(gmkPath);
				};
				default:
			};
			return;
		} // gmkSplitPath not set
		//
		var splitPath = Path.withExtension(gmkPath, "gmksplit");
		var targetPath = splitPath + "/Global Game Settings.xml";
		if (FileSystem.existsSync(splitPath) && FileSystem.existsSync(targetPath)) {
			if (Preferences.current.gmkSplitOpenExisting) {
				Project.open(targetPath);
				return;
			} else switch (Dialog.showMessageBox({
				message: [
					'`$splitPath` already exists!',
					'If you want to re-generate the directory from the updated .$gmkExt file, remove the directory first.',
					"",
					"You can also bypass this dialog by opening `Global Game Settings.xml` in .gmksplit directory with GMEdit."
				].join("\n"),
				buttons: [
					"Open existing",
					"Don't show this again"
				],
			})) {
				case 0: {
					Project.open(targetPath);
					return;
				};
				case 1: {
					Preferences.current.gmkSplitOpenExisting = true;
					Preferences.save();
					Project.open(targetPath);
					return;
				};
				default: return;
			}
		}
		//
		var gmkSplitArgs = [gmkPath, splitPath];
		if (Path.extension(gmkSplitPath).toLowerCase() == "jar") {
			gmkSplitArgs.unshift(gmkSplitPath);
			gmkSplitPath = "java";
		}
		//
		Project.nameNode.innerText = "Converting...";
		Main.window.setTimeout(function() {
			var cpr:Dynamic = (cast Main.window).require("child_process");
			var proc = cpr.spawn(gmkSplitPath, gmkSplitArgs);
			proc.stdout.on('data', function(data) {
				Main.console.log('gmksplit:\n' + data);
			});
			proc.stderr.on('data', function(data) {
				Main.console.error('gmksplit:\n' + data);
			});
			proc.on("close", function(code) {
				if (code != 0) {
					Dialog.showError("gmk-splitter failed to convert your file!"
						+ "\nCheck the JavaScript console (Ctrl+Shift+I) for output");
					return;
				}
				if (FileSystem.existsSync(targetPath)) Project.open(targetPath);
			});
		}, 10);
	}
}