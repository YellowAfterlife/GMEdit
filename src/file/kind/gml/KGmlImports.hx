package file.kind.gml;
import editors.Editor;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmlImports extends KGmlScript {
	public static var inst:KGmlImports = new KGmlImports();
	override public function checkForChanges(editor:Editor):Int {
		var result = super.checkForChanges(editor);
		if (result < 0) result = 0; // it's OK to not exist for an import file
		return result;
	}
}
