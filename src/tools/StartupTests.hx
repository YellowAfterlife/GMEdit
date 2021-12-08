package tools;
import electron.Dialog;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class StartupTests {
	static function assert<T>(value:T, want:T, desc:String) {
		if (value != want) {
			Dialog.showError('Assertion failed for $desc!'
				+ '\nwanted: $want'
				+ '\ngot: $value'
			);
		}
	}
	public static function main() {
		var d = new Dictionary();
		d["a"] = 1;
		d["b"] = 1;
		assert(d.size(), 2, "Dictionary.size");
	}
}