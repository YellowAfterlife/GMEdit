package file.kind.misc;

import file.kind.KCode;

/**
 * ...
 * @author YellowAfterlife
 */
class KMarkdown extends KCode {
	public var isDocMd:Bool;
	public function new(dmd:Bool) {
		super();
		isDocMd = dmd;
		modePath = "ace/mode/markdown";
	}
	
}
