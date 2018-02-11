package ui;
import Main.document;
import gml.GmlAPI;
import gml.GmlVersion;
import js.html.Event;
import js.html.DragEvent;
import electron.Dialog;
import haxe.io.Path;
import gml.Project;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class FileDrag {
	public static function handle(path:String) {
		var name = Path.withoutDirectory(path);
		inline function decline():Void {
			Dialog.showMessageBox({
				type: DialogMessageType.Error,
				message: "No idea how to load file type for " + name,
				buttons: ["OK"]
			});
		}
		switch (Path.withoutDirectory(path)) {
			case "main.cfg", "main.txt": {
				Project.open(path);
				return;
			};
		}
		switch (Path.extension(path)) {
			case "gmx": {
				switch (Path.extension(Path.withoutExtension(path))) {
					case "project": Project.open(path);
					case "object", "config": {
						GmlFile.open(
							Path.withoutExtension(Path.withoutExtension(name)),
							path);
					};
				}
			};
			case "yy": {
				var pair = gml.file.GmlFileKindTools.detect(path);
				if (pair.kind != Extern) GmlFile.open(name, path);
			};
			case "yyp": Project.open(path);
			case "gml": {
				if (GmlAPI.version == GmlVersion.none) GmlAPI.version = GmlVersion.v1;
				GmlFile.open(Path.withoutExtension(name), path);
			};
			default: decline();
		}
	}
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
			handle(untyped file.path);
		});
	}
}
