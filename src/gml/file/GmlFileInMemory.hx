package gml.file;

import tools.Random;
import file.FileKind;
import tools.Aliases.GmlCode;

class GmlFileInMemory extends GmlFile {
	var content : GmlCode;

	public function new(name:String, kind:FileKind, content:GmlCode, ?path:String, ?data:Dynamic) {
		// Generate a random path since sometimes paths are used for identifiers
		if (path == null) {
			path = Random.letterString(8);
		}
		this.content = content;
		super(name, path, kind, data);
	}

	override public function existsContent() : Bool {
		return true;
	}

	override public function writeContent(code : GmlCode) {
		content = code;
	}

	override public function readContent() : GmlCode {
		return content;
	}

	override public function syncTime() {
		// Purposefully left blank
	}
}