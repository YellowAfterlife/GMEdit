package yy.v22;
import haxe.Rest;
import tools.Dictionary;
import yy.YyGUID;
import js.html.Console;

/**
 * ...
 * @author YellowAfterlife
 */
class YyGUIDCollisionChecker {
	var items:Dictionary<Array<Any>> = new Dictionary();
	var context:Array<Any>;
	public function new(ctx:Rest<Any>) {
		context = ctx.toArray();
	}
	public function add(guid:YyGUID, rest:Rest<Any>) {
		var arr = rest.toArray();
		if (items.exists(guid)) {
			Console.error("GUID collision in " + context.join(" ")
				+ ": GUID " + guid + " (" + arr.join(" ")
				+ ") is already used (for " + items[guid].join(" ")
				+ "). IDE may decline to load your project, corrupt it upon importing to 2.3, or otherwise act unusual."
			);
		} else items[guid] = arr;
	}
}
