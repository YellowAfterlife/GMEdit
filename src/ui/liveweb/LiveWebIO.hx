package ui.liveweb;
import electron.Dialog;
import haxe.io.Bytes;
import haxe.io.Path;
import js.lib.ArrayBuffer;
import js.html.File;
import js.html.FileList;
import tools.BufferTools;

/**
 * ...
 * @author YellowAfterlife
 */
class LiveWebIO {
	public static function importDialog() {
		Dialog.showOpenDialogWrap({
			filters: [
				new DialogFilter("GameMaker files", ["gml"]),
				new DialogFilter("Archives with GML files", ["zip"]),
			],
		}, function(files:FileList) {
			for (file in files) acceptFile(file);
		});
	}
	public static function exportDialog() {
		var pairs = LiveWebState.getPairs();
		if (pairs.length == 0) return;
		if (pairs.length == 1) {
			BufferTools.saveAs(Bytes.ofString(pairs[0].code), pairs[0].name + ".gml", "text/gml");
			return;
		}
		//
		var output = new haxe.io.BytesOutput();
		var writer = new haxe.zip.Writer(output);
		var entries = new List();
		var now = Date.now();
		for (pair in pairs) {
			var bytes = Bytes.ofString(pair.code);
			entries.push({
				fileName: pair.name + ".gml",
				fileSize: bytes.length,
				fileTime: now,
				compressed: false,
				dataSize: bytes.length,
				data: bytes,
				crc32: haxe.crypto.Crc32.make(bytes)
			});
		}
		writer.write(entries);
		var zip = output.getBytes().sub(0, output.length);
		BufferTools.saveAs(zip, pairs[0].name + ".zip", "application/zip");
	}
	public static function acceptFile(file:File) {
		switch (Path.extension(file.name).toLowerCase()) {
			case "gml": {
				var reader = new js.html.FileReader();
				reader.onloadend = function(_) {
					LiveWeb.addTab(Path.withoutExtension(file.name), reader.result);
				};
				reader.readAsText(file);
			};
			case "zip": {
				var reader = new js.html.FileReader();
				reader.onloadend = function(_) {
					try {
						var abuf:ArrayBuffer = reader.result;
						var bytes = Bytes.ofData(abuf);
						var input = new haxe.io.BytesInput(bytes);
						var entries = haxe.zip.Reader.readZip(input);
						for (entry in entries) {
							var path = entry.fileName;
							if (Path.extension(path).toLowerCase() != "gml") continue;
							var data = entry.data;
							if (data == null) continue;
							if (entry.compressed) data = BufferTools.inflate(data);
							LiveWeb.addTab(Path.withoutExtension(path), data.toString());
						}
					} catch (_:Dynamic) {
						
					}
				};
				reader.readAsArrayBuffer(file);
			};
		}
	}
}
