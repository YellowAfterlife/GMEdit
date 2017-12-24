package ui;
import Main.document;
import js.html.Event;
import js.html.DragEvent;
import electron.Dialog;
import haxe.io.Path;
import gml.Project;
import gml.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class FileDrag {
	public static function init() {
		function cancelDefault(e:Event) {
			e.preventDefault();
			return false;
		}
		document.body.addEventListener("dragover", cancelDefault);
		document.body.addEventListener("dragenter", cancelDefault);
		document.body.addEventListener("dragleave", cancelDefault);
		document.body.addEventListener("drop", function(e:DragEvent) {
			e.preventDefault();
			var file = e.dataTransfer.files[0];
			if (file == null) return;
			var path:String = untyped file.path;
			inline function decline():Void {
				Dialog.showMessageBox({
					type: DialogMessageType.Error,
					message: "No idea how to load file type for " + file.name,
					buttons: ["OK"]
				});
			}
			switch (Path.withoutDirectory(path)) {
				case "main.cfg", "main.txt": {
					Project.current = new Project(path);
					return;
				};
			}
			switch (Path.extension(path)) {
				case "gmx": {
					switch (Path.extension(Path.withoutExtension(path))) {
						case "project": {
							Project.current = new Project(path);
						};
						case "object", "config": {
							GmlFile.open(
								Path.withoutExtension(Path.withoutExtension(file.name)),
								path);
						};
					}
				};
				case "yyp": {
					Project.current = new Project(path);
				};
				case "gml": {
					GmlFile.open(Path.withoutExtension(file.name), path);
				};
				default: decline();
			}
		});
	}
}
