package ui;
import Main.document;
import electron.FileSystem;
import gml.GmlAPI;
import gml.GmlVersion;
import gml.file.GmlFileKindTools;
import js.html.Event;
import js.html.DragEvent;
import electron.Dialog;
import haxe.io.Path;
import gml.Project;
import gml.file.GmlFile;
import file.kind.misc.KExtern;
import yy.zip.YyZip;

/**
 * This little class allows you to drag and drop files onto GMEdit window.
 * @author YellowAfterlife
 */
class FileDrag {
	public static function handle(path:String, file:js.html.File) {
		var rel = Path.withoutDirectory(path);
		var name = Path.withoutDirectory(path);
		inline function decline():Void {
			Dialog.showMessageBox({
				type: DialogMessageType.Error,
				message: "No idea how to load file type for " + name,
				buttons: ["OK"]
			});
		}
		switch (rel) {
			case "main.cfg", "main.txt": {
				Project.open(path);
				return;
			};
		}
		switch (Path.extension(path).toLowerCase()) {
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
			case "yyp": Project.open(path);
			case "gmd", "gmk", "gm81": gmk.GmkSplit.proc(path);
			case "gmk-snips": Project.open(path);
			case "xml" if (rel == "Global Game Settings.xml"): Project.open(path);
			case "gml": {
				if (GmlAPI.version == GmlVersion.none) GmlAPI.version = GmlVersion.v1;
				GmlFile.open(Path.withoutExtension(name), path);
			};
			case "yyz", "zip": {
				if (file != null) {
					var reader = new js.html.FileReader();
					reader.onloadend = function(_) {
						var abuf:js.lib.ArrayBuffer = reader.result;
						var bytes = haxe.io.Bytes.ofData(abuf);
						yy.zip.YyZip.open(path, bytes);
					};
					reader.readAsArrayBuffer(file);
				} else {
					var data = FileSystem.readFileSync(path);
					var bytes = haxe.io.Bytes.ofData(data);
					yy.zip.YyZip.open(path, bytes);
				}
			};
			default: {
				var ppair = tools.PathTools.ptDetectProject(path);
				if (ppair.version != GmlVersion.none) {
					Project.open(path);
				} else {
					var pair = GmlFileKindTools.detect(path);
					if (pair.kind != KExtern.inst) {
						GmlFile.open(Path.withoutExtension(name), path);
					} else decline();
				}
			};
		}
	}
	public static function init() {
		function cancelDefault(e:Event) {
			e.preventDefault();
			return false;
		}
		document.body.addEventListener("dragover", cancelDefault);
		document.body.addEventListener("dragenter", cancelDefault);
		document.body.addEventListener("drop", function(e:DragEvent) {
			e.preventDefault();
			//Console.log(e.dataTransfer.files);
			#if gmedit.live
			for (file in e.dataTransfer.files) {
				ui.liveweb.LiveWebIO.acceptFile(file);
			}
			#else
			var file = e.dataTransfer.files[0];
			if (file == null) return;
			var path = file.name;
			if (electron.Electron.isAvailable()) {
				var fpath = (cast file).path;
				if (fpath == null && electron.Electron.webUtils != null) {
					fpath = electron.Electron.webUtils.getPathForFile(file);
				}
				if (fpath != null) path = fpath;
			}
			handle(path, file);
			#end
		});
	}
}
