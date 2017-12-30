package gml;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlKeycode {
	private static var names:Array<String> = initNames();
	private static function initNames() {
		var r:Array<String> = [], i;
		tools.NativeArray.clearResize(r, 256);
		//
		i = "A".code; while (i <= "Z".code) {
			r[i++] = String.fromCharCode(i);
		}
		i = "0".code; while (i <= "9".code) {
			r[i++] = 'd' + String.fromCharCode(i);
		}
		//{ autogen from fnames:
		r[0] = "vk_nokey";
		r[1] = "vk_anykey";
		r[13] = "vk_enter";
		r[13] = "vk_return";
		r[16] = "vk_shift";
		r[17] = "vk_control";
		r[18] = "vk_alt";
		r[27] = "vk_escape";
		r[32] = "vk_space";
		r[8] = "vk_backspace";
		r[9] = "vk_tab";
		r[19] = "vk_pause";
		r[44] = "vk_printscreen";
		r[37] = "vk_left";
		r[39] = "vk_right";
		r[38] = "vk_up";
		r[40] = "vk_down";
		r[36] = "vk_home";
		r[35] = "vk_end";
		r[46] = "vk_delete";
		r[45] = "vk_insert";
		r[33] = "vk_pageup";
		r[34] = "vk_pagedown";
		r[112] = "vk_f1";
		r[113] = "vk_f2";
		r[114] = "vk_f3";
		r[115] = "vk_f4";
		r[116] = "vk_f5";
		r[117] = "vk_f6";
		r[118] = "vk_f7";
		r[119] = "vk_f8";
		r[120] = "vk_f9";
		r[121] = "vk_f10";
		r[122] = "vk_f11";
		r[123] = "vk_f12";
		r[96] = "vk_numpad0";
		r[97] = "vk_numpad1";
		r[98] = "vk_numpad2";
		r[99] = "vk_numpad3";
		r[100] = "vk_numpad4";
		r[101] = "vk_numpad5";
		r[102] = "vk_numpad6";
		r[103] = "vk_numpad7";
		r[104] = "vk_numpad8";
		r[105] = "vk_numpad9";
		r[111] = "vk_divide";
		r[106] = "vk_multiply";
		r[109] = "vk_subtract";
		r[107] = "vk_add";
		r[110] = "vk_decimal";
		r[160] = "vk_lshift";
		r[162] = "vk_lcontrol";
		r[164] = "vk_lalt";
		r[161] = "vk_rshift";
		r[163] = "vk_rcontrol";
		r[165] = "vk_ralt";
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
		return r;
	}
	//
	public static function fromName(s:String):Null<Int> {
		var r = codes[s];
		if (r == null) {
			return Std.parseInt(s);
		} else return r;
	}
	public static function toName(k:Int):String {
		var r = names[k];
		if (r == null) {
			return Std.string(k);
		} else return r;
	}
}
