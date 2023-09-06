function coro_wait(coro, time) {
	var fn = method({ coro: coro }, function() {
		coro.next();
	});
	return call_later(time, time_source_units_seconds, fn);
}