package file.kind.misc;

import file.kind.KCode;

/**
 * ...
 * @author YellowAfterlife
 */
class KJavaScript extends KCode {
	public static var inst:KJavaScript = new KJavaScript();
	public function new() {
		super();
		modePath = "ace/mode/javascript";
	}
	
}
