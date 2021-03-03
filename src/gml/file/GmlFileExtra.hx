package gml.file;

/**
 * Additional metadata, mostly for "combined view"
 * @author YellowAfterlife
 */
class GmlFileExtra {
	public var path:String;
	public var time:Float = 0;
	public function new(path:String) {
		this.path = path;
	}
}
