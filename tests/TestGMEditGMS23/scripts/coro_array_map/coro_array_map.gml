coro_array_map_test();
function coro_array_map(arr) {
	var l_argc = argument_count;
	var l_args = array_create(l_argc);
	while (--l_argc >= 0) l_args[l_argc] = argument[l_argc];
	return new coro_array_map_coroutine(l_args);
}
function coro_array_map_coroutine(_args) constructor {
	__label__ = 0;
	result = undefined;
	__argument__ = _args;
	static next = function(_yield_result = undefined) {
		result = _yield_result;
		while (true) switch (__label__) {
		case 0/* [L2,c29] begin */:
			n = array_length(__argument__[0]);
			i = 0;
		case 1/* [L4,c2] check for */:
			if (i >= n) { __label__ = 4; continue; }
			// [inline yield]
			result = __argument__[0][i]; __label__ = 2; return true;
		case 2/* [L5,c12] post yield */:
			__result_0__ = result;
			__argument__[0][i] = __result_0__;
		case 3/* [L4,c2] post for */:
			i++;
			__label__ = 1; continue;
		case 4/* [L4,c2] end for */:
		default/* [L15,c22] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_array_map_test() {
	var arr = [1, 2, 3];
	var co = coro_array_map(arr);
	while (co.next()) { }
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_array_map"]}

/*//!#gmcr
#gmcr
function coro_array_map(arr){
	var n = array_length(arr);
	for (var i = 0; i < n; i++) {
		arr[i] = yield arr[i];
	}
}
function coro_array_map_test() {
	var arr = [1, 2, 3];
	var co = coro_array_map(arr);
	while (co.next()) {
		
	}
}
coro_array_map_test();
//!#gmcr*/
