package editors;

import electron.FileWrap;
import file.kind.yy.KYyFont;
import gml.file.GmlFile;
import Main.document;

class EditFont extends Editor {
	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
	}

	public override function load(data:Dynamic) {
		super.load(data);

		if (Std.is(file.kind, KYyFont) == false) {
			return;
		}

		if (data == null) data = FileWrap.readYyFileSync(file.path);


		var optionsDiv = document.createDivElement();
		var previewDiv = document.createDivElement();

		element.appendChild(optionsDiv);
		element.appendChild(previewDiv);
	}
}