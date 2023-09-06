coro_arr_method_test();
function coro_arr_method(arr) {
	var l_argc = argument_count;
	var l_args = array_create(l_argc);
	while (--l_argc >= 0) l_args[l_argc] = argument[l_argc];
	var l_scope = {
		__label__: 0,
		__argument__: l_args,
	}, l_function;
	with (l_scope) l_function = function() {
		while (true) switch (__label__) {
		case 0/* [L2,c31] begin */:
			n = array_length(__argument__[0]);
			i = 0;
		case 1/* [L4,c2] check for */:
			if (i >= n) { __label__ = 4; continue; }
			__function__.result = __argument__[0][i]; __label__ = 2; return true;
		case 2/* [L5,c3] post yield */:
		case 3/* [L4,c2] post for */:
			i++;
			__label__ = 1; continue;
		case 4/* [L4,c2] end for */:
		default/* [L21,c0] end */:
			__function__.result = undefined; __label__ = -1; return false;
		}
	}
	l_scope.__function__ = l_function;
	return l_function;
}

function coro_arr_method_test() {
	var arr = ["a", "b", "c"];
	var ca = coro_arr_method(arr);
	var s;
	for (var i = 0; i < array_length(arr); i++) {
		var r = ca();
		s = r; ///want_warn
		assert(r, 1);
		assert(ca.result, arr[i]);
	}
	assert(ca(), 0);
}

// @gmcr {"mode":"method","yieldScripts":["coro_arr_method"]}

/*//!#gmcr
#gmcr method
function coro_arr_method(arr) {
	var n = array_length(arr);
	for (var i = 0; i < n; i++) {
		yield arr[i];
	}
}
function coro_arr_method_test() {
	var arr = ["a", "b", "c"];
	var ca := coro_arr_method(arr);
	var s/*:string*\endco\/;
	for (var i = 0; i < array_length(arr); i++) {
		var r := ca();
		s = r; ///want_warn
		assert(r, true);
		assert(ca.result, arr[i]);
	}
	assert(ca(), false);
}
coro_arr_method_test();

//!#gmcr*/
