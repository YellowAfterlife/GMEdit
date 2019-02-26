package file.kind.misc;

/**
 * ...
 * @author YellowAfterlife
 */
class KPlain extends KCode {
	public static var inst:KPlain = new KPlain();
	public function new() {
		super();
		modePath = "ace/mode/text";
	}
	
}
