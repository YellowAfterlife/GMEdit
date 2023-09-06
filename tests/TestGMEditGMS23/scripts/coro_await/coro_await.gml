global.coro_http_map = ds_map_create();
coro_await_test();
function coro_await() {
	return new coro_await_coroutine();
}
function coro_await_coroutine() constructor {
	__label__ = 0;
	result = undefined;
	static next = function(_yield_result = undefined) {
		result = _yield_result;
		while (true) switch (__label__) {
		case 0/* [L2,c23] begin */:
			// [inline yield]
			result = coro_http_get(self, "https://yal.cc/ping"); __label__ = 1; return true;
		case 1/* [L3,c10] post yield */:
			__result_0__ = result;
			a = __result_0__;
			result = coro_wait(self, 5); __label__ = 2; return true;
		case 2/* [L4,c2] post yield */:
			// [inline yield]
			result = coro_http_get(self, "https://yal.cc/ping"); __label__ = 3; return true;
		case 3/* [L5,c10] post yield */:
			__result_0__ = result;
			b = __result_0__;
			show_message([a, b]);
		default/* [L28,c18] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_await_test() {
	coro_await().next();
}

function coro_http_get(coro, url) {
	ds_map_set(global.coro_http_map, http_get(argument1), argument0);
	return 1;
}

function coro_http_async() {
	var _status = ds_map_find_value(async_load, "status");
	if (_status > 0) exit;
	var _id = ds_map_find_value(async_load, "id");
	var _coro = ds_map_find_value(global.coro_http_map, _id);
	if (_coro == undefined) exit;
	_coro.next(ds_map_find_value(async_load, "result"));
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_await"]}

/*//!#gmcr
#gmcr
function coro_await() {
	var a = yield coro_http_get(local, "https://yal.cc/ping");
	yield coro_wait(local, 5);
	var b = yield coro_http_get(local, "https://yal.cc/ping");
	show_message([a, b]);
}
function coro_await_test() {
	coro_await().next();
}

global.coro_http_map = ds_map_create();
function coro_http_get(coro, url) {
	global.coro_http_map[?http_get(url)] = coro;
	return true;
}
function coro_http_async() {
	var _status = async_load[?"status"];
	if (_status > 0) exit;
	
	var _id = async_load[?"id"];
	var _coro = global.coro_http_map[?_id];
	if (_coro == undefined) exit;
	
	_coro.next(async_load[?"result"]);
}

coro_await_test();
//!#gmcr*/
