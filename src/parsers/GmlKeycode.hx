package parsers;
import ace.AceWrap;
import ace.extern.*;
import tools.Dictionary;
import tools.NativeString;

/**
 * Maps keyboard key names for use in events.
 * @author YellowAfterlife
 */
class GmlKeycode {
	public static var comp:AceAutoCompleteItems = [];
	private static var names:Array<String> = initNames();
	private static function initNames() {
		var r:Array<String> = [], i;
		tools.NativeArray.clearResize(r, 256);
		//
		i = "A".code; while (i <= "Z".code) {
			r[i] = String.fromCharCode(i);
			i += 1;
		}
		i = "0".code; while (i <= "9".code) {
			r[i] = String.fromCharCode(i);
			i += 1;
		}
		function add(k:Int, s:String) {
			r[k] = s;
			comp.push(new AceAutoCompleteItem(s, "key", "key" + k));
		}
		//{ autogen from fnames:
		add(0, "vk_nokey");
		add(1, "vk_anykey");
		add(8, "vk_backspace");
		add(9, "vk_tab");
		add(13, "vk_return");
		add(16, "vk_shift");
		add(17, "vk_control");
		add(18, "vk_alt");
		add(19, "vk_pause");
		add(27, "vk_escape");
		add(32, "vk_space");
		add(33, "vk_pageup");
		add(34, "vk_pagedown");
		add(35, "vk_end");
		add(36, "vk_home");
		add(37, "vk_left");
		add(38, "vk_up");
		add(39, "vk_right");
		add(40, "vk_down");
		add(44, "vk_printscreen");
		add(45, "vk_insert");
		add(46, "vk_delete");
		add(96, "vk_numpad0");
		add(97, "vk_numpad1");
		add(98, "vk_numpad2");
		add(99, "vk_numpad3");
		add(100, "vk_numpad4");
		add(101, "vk_numpad5");
		add(102, "vk_numpad6");
		add(103, "vk_numpad7");
		add(104, "vk_numpad8");
		add(105, "vk_numpad9");
		add(106, "vk_multiply");
		add(107, "vk_add");
		add(109, "vk_subtract");
		add(110, "vk_decimal");
		add(111, "vk_divide");
		add(112, "vk_f1");
		add(113, "vk_f2");
		add(114, "vk_f3");
		add(115, "vk_f4");
		add(116, "vk_f5");
		add(117, "vk_f6");
		add(118, "vk_f7");
		add(119, "vk_f8");
		add(120, "vk_f9");
		add(121, "vk_f10");
		add(122, "vk_f11");
		add(123, "vk_f12");
		add(160, "vk_lshift");
		add(161, "vk_rshift");
		add(162, "vk_lcontrol");
		add(163, "vk_rcontrol");
		add(164, "vk_lalt");
		add(165, "vk_ralt");
		//}
		return r;
	}
	//
	private static var codes:Dictionary<Int> = initCodes(names);
	private static function initCodes(names:Array<String>) {
		var r = new Dictionary();
		for (k in 0 ... names.length) {
			var name = names[k];
			if (name != null) r.set(name, k);
		}
		for (k in "A".code ... "Z".code + 1) {
			r.set(String.fromCharCode(k + ("a".code - "A".code)), k);
		}
		return r;
	}
	//
	public static inline function fromName(s:String):Null<Int> {
		var r = codes[s];
		if (r == null) {
			if (NativeString.startsWith(s, "key")) {
				return Std.parseInt(s.substring(3));
			} else return null;
		} else return r;
	}
	public static function toName(k:Int):String {
		var r = names[k];
		if (r == null) {
			return "key" + k;
		} else return r;
	}
}
