package file.kind.gml;
import editors.EditCode;
import gml.file.GmlFile;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmlSearchResults extends KCode {
	public static var inst:KGmlSearchResults = new KGmlSearchResults();
	private static var nextId:Int = 0;
	public function new() {
		super();
		modePath = "ace/mode/gml_search";
	}
	override public function getTabContext(file:GmlFile, data:Dynamic):String {
		return file.name + "#" + (nextId++);
	}
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		return data;
	}
	override public function saveCode(editor:EditCode, code:String):Bool {
		var file = editor.file;
		if (file.searchData == null) return false;
		if (!file.searchData.save(file)) return false;
		file.markClean();
		return true;
	}
}
