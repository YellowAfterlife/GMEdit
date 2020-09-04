package ace.extern;
import ace.extern.AceUserAgent;
import haxe.extern.EitherType;
import tools.JsTools;
import tools.NativeString;
import haxe.Constraints;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract AceCommand(AceCommandImpl) from AceCommandImpl to AceCommandImpl {
	private static function bindToAccel(b:String):String {
		return NativeString.replaceExt(b, AceMacro.jsRx(~/\b-\b/g), "+");
	}
	public function getAccelerator():String {
		var key:AceCommandKey = this.bindKey;
		if (Std.is(key, String)) return bindToAccel(key);
		var pair:AceCommandKeyPair = key;
		return bindToAccel(AceUserAgent.isMac ? pair.mac : pair.win);
	}
}
typedef AceCommandImpl = {
	?bindKey:AceCommandKey,
	exec:AceWrap->Void,
	/** Used for bindings */
	name:String,
	/** A descriptive name for settings */
	?title:String,
	?readOnly:Bool,
	?scrollIntoView:String,
	?multiSelectAction:String,
};

/** "ctrl-K" or { win:"ctrl-K", mac:"cmd-K" } */
abstract AceCommandKey(Dynamic)
from String from AceCommandKeyPair
to   String to   AceCommandKeyPair {
	public var key(get, never):String;
	private function get_key():String {
		if (this == null || Std.is(this, String)) return this;
		return (AceUserAgent.isMac ? (this:AceCommandKeyPair).mac : (this:AceCommandKeyPair).win);
	}
	
	/** "alt-a" -> "Alt+A" */
	public static function prettyprint(keybindString:String) {
		return NativeString.replaceExt(keybindString,
			JsTools.rx(~/(^|-)(\w)/g),
		function(_, dash:String, letter:String) {
			return dash != "" ? "+" + letter.toUpperCase() : letter.toUpperCase();
		});
	}
	
	/** "alt-a" -> "Alt+A" */
	public inline function toDisplayString():String {
		return prettyprint(key);
	}
}
typedef AceCommandKeyPair = { win:String, mac:String };

/** command object or name of an existing command */
abstract AceCommandOrName(Dynamic)
from String from AceCommand
to   String to   AceCommand {
	public var name(get, never):String;
	private inline function get_name():String {
		return Std.is(this, String) ? this : (this:AceCommand).name;
	}
	
	public function equals(other:AceCommandOrName) {
		if (Std.is(this, String)) {
			if (Std.is(other, String)) {
				return this == other;
			} else {
				return this == (other:AceCommand).name;
			}
		} else {
			if (Std.is(other, String)) {
				return (this:AceCommand).name == other;
			} else {
				return this == other;
			}
		}
	}
}

/** I can't believe you've done this */
abstract AceOneOrMoreCommandOrName(Dynamic)
from AceCommandOrName from Array<AceCommandOrName>
to   AceCommandOrName   to Array<AceCommandOrName> {
	public var first(get, never):AceCommandOrName;
	private inline function get_first():AceCommandOrName {
		return Std.is(this, Array) ? this[0] : this;
	}
	//
	public inline function isArray():Bool {
		return Std.is(this, Array);
	}
	public inline function asItem():AceCommandOrName {
		return this;
	}
	public inline function asArray():Array<AceCommandOrName> {
		return this;
	}
	public inline function toArray():Array<AceCommandOrName> {
		return isArray() ? asArray() : [asItem()];
	}
	//
	public inline function forEach(fn:AceCommandOrName->Void):Void {
		if (isArray()) {
			for (val in asArray()) fn(val);
		} else fn(asItem());
	}
}

/** command / name / function */
typedef AceCommandInit = EitherType<AceCommandOrName, Function>;
