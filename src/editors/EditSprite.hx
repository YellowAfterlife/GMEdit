package editors;

import gml.file.GmlFile;
import haxe.io.Path;
using tools.HtmlTools;
import yy.YySprite;
import Main.document;

/**
 * ...
 * @author YellowAfterlife
 */
class EditSprite extends Editor {
	
	public function new(file:GmlFile) {
		super(file);
		element = Main.document.createDivElement();
		element.classList.add("resinfo");
		element.classList.add("sprite");
	}
	override public function load(data:Dynamic):Void {
		var q:YySprite = data;
		element.clearInner();
		//
		var t = document.createSpanElement();
		t.setInnerText(q.frames.length + " subimage" + (q.frames.length != 1 ? "s" : "") +":");
		element.appendChild(t);
		//
		element.appendChild(document.createBRElement());
		var dir = Path.directory(file.path);
		for (frame in q.frames) {
			var img = document.createImageElement();
			img.src = Path.join([dir, frame.id + ".png"]);
			element.appendChild(img);
		}
		//
	}
}
