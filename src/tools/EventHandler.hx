package tools;

/** An Event that's subscribleable to. When invoked, all the functions that's been added to it will be executed. */
class EventHandler<T> {
	private var listeners: Array< (T) -> Void >;
	/** Creates a new empty EventHandler */
	public function new() {
		listeners = new Array();
	}

	/** Adds a function to be executed when the event is invoked */
	public function listen( listener: (T) -> Void ) {
		listeners.push(listener);
	}

	/** Removes a listener from the EventHandler */
	public function remove( listener: (T) -> Void ) {
		listeners.remove(listener);
	}

	/** Removes all listeners to the Event */
	public function clear() {
		listeners = [];
	}

	/** Invoke the event, calling all functions listening to it*/
	public function invoke(parameter: T) {
		for (listener in listeners) {
			listener(parameter);
		}
	}
}
