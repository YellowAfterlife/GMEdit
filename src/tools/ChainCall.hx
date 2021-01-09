package tools;
import js.lib.Function;

/**
 * A really simple wrapper for calling 
 * @author YellowAfterlife
 */
class ChainCall {
	var queue:Array<ChainThen> = [];
	var isRunning = false;
	public function new() {
		
	}
	function next() {
		var item = queue.shift();
		if (item != null) {
			isRunning = true;
			item.fn.apply(null, item.args);
		} else isRunning = false;
	}
	public function stop():Void {
		queue.resize(0);
	}
	public function call<T, A>(fn:A->ChainFn<T>->Void, a:A, cb:ChainFn<T>) {
		function fin(val:T) {
			cb(val);
			next();
		}
		var q:ChainThen = {
			fn: cast fn,
			args: [a, fin]
		};
		queue.push(q);
		if (!isRunning) next();
		return this;
	}
}
typedef ChainThen = {
	fn:Function,
	args:Array<Dynamic>,
};
typedef ChainFn<T> = T->Void;