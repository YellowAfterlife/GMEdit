package ace.extern;

/**
 * ace/lib/event_emitter
 * @author YellowAfterlife
 */
extern interface AceEventEmitter<T> {
	function new();
	function on(eventName:String, callback:AceEventListener<Any, T>, ?capturing:Bool):Void;
	function off(eventName:String, callback:AceEventListener<Any, T>):Void;
	function once(eventName:String, callback:AceEventListener<Any, T>):Void;
	
	function setDefaultHandler(eventName:String, callback:AceEventListener<Any, T>):Void;
	function removeDefaultHandler(eventName:String, callback:AceEventListener<Any, T>):Void;
	
	function removeAllListeners(eventName:String):Void;
	
	@:native("_emit") function emit<E:{}>(eventName:String, ?e:E):Dynamic;
	
	/**
	 * Dispatches a value as-is, does't handle stopPropagation/preventDefault.
	 */
	@:native("_signal") function signal<E>(eventName:String, e:E):Void;
	
}
typedef AceEventListener<E, T> = (e:E, self:T)->Void;
