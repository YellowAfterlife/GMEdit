package tools;
import js.html.Console;

/**
 * As of yet, unused
 * @author YellowAfterlife
 */
class ExecQueue<T> {
	public var maxAtOnce:Int;
	public var onProc:ExecQueueFunc<T>;
	public var isRunning:Bool = false;
	public var isDone:Bool = false;
	public var onDone:Void->Void = null;
	/// how many items are being processed right now
	public var numRunning:Int = 0;
	
	public var queue:Array<T> = [];
	public function new(fn:ExecQueueFunc<T>, maxAtOnce:Int = 8) {
		onProc = fn;
		this.maxAtOnce = maxAtOnce;
	}
	function proc(val:T) {
		numRunning++;
		onProc(val, next);
	}
	function next() {
		numRunning--;
		if (queue.length > 0) {
			proc(queue.shift());
		} else if (numRunning <= 0) {
			if (isDone) {
				if (onDone != null) Console.warn("Last item finished but we've already dispatched onDone");
			} else {
				isDone = true;
				if (onDone != null) onDone();
			}
		}
	}
	public function add(val:T) {
		if (isRunning && numRunning < maxAtOnce) {
			proc(val);
		} else queue.push(val);
	}
	public function run() {
		var n = queue.length;
		if (n > maxAtOnce) n = maxAtOnce;
		isRunning = true;
	}
}
typedef ExecQueueFunc<T> = (val:T, next:Void->Void)->Void;
