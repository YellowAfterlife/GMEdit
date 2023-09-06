// linear generator isn't as convenient but it stores everything in a couple arrays
// instead of a struct (which takes up less memory)
// also good for compatibility with old projects
// (as this was the only generator for GMS<2.3)
coro_arr_linear_test();
function coro_arr_linear(arr) {
	var l_ctx = argument[0];
	if (!is_array(l_ctx)) {
		l_ctx = array_create(5);
		var l_argc = argument_count - 1;
		var l_args = array_create(l_argc);
		while (--l_argc >= 0) l_args[@l_argc] = argument[l_argc + 1];
		l_ctx[2/* args */] = l_args;
		return l_ctx;
	}
	var l_args = l_ctx[2/* args */];
	while (true) switch (l_ctx[1/* label */]) {
	case 0/* [L6,c31] begin */:
		/// @param ctx
		l_ctx[@3/* n */] = array_length(l_args[0]);
		l_ctx[@4/* i */] = 0;
	case 1/* [L8,c2] check for */:
		if (l_ctx[4/* i */] >= l_ctx[3/* n */]) { l_ctx[@1/* label */] = 4; continue; }
		l_ctx[@0/* yield */] = l_args[0][l_ctx[4/* i */]]; l_ctx[@1/* label */] = 2; return true;
	case 2/* [L9,c3] post yield */:
	case 3/* [L8,c2] post for */:
		l_ctx[@4/* i */]++;
		l_ctx[@1/* label */] = 1; continue;
	case 4/* [L8,c2] end for */:
	default/* [L27,c0] end */:
		l_ctx[@0/* yield */] = undefined; l_ctx[@1/* label */] = -1; array_resize(l_args, 2); return false;
	}
}

function coro_arr_linear_test() {
	var arr = ["a", "b", "c"];
	var ca = coro_arr_linear(0, arr);
	var k, a;
	k = ca[1]; // label
	a = ca[1]; ///want_warn
	k = ca[2]; ///want_warn
	a = ca[2]; // args
	for (var i = 0; i < array_length(arr); i++) {
		assert(coro_arr_linear(ca), 1);
		assert(ca[0], arr[i]);
	}
	assert(coro_arr_linear(ca), 0);
}

// @gmcr {"mode":"linear","yieldScripts":["coro_arr_linear"]}

/*//!#gmcr
#gmcr linear
// linear generator isn't as convenient but it stores everything in a couple arrays
// instead of a struct (which takes up less memory)
// also good for compatibility with old projects
// (as this was the only generator for GMS<2.3)
function coro_arr_linear(arr) {
	var n = array_length(arr);
	for (var i = 0; i < n; i++) {
		yield arr[i];
	}
}
function coro_arr_linear_test() {
	var arr = ["a", "b", "c"];
	var ca := coro_arr_linear(0, arr);
	var k/*:int*\endco\/, a/*:array*\endco\/;
	k = ca[1]; // label
	a = ca[1]; ///want_warn
	k = ca[2]; ///want_warn
	a = ca[2]; // args
	for (var i = 0; i < array_length(arr); i++) {
		assert(coro_arr_linear(ca), true);
		assert(ca[0], arr[i]);
	}
	assert(coro_arr_linear(ca), false);
}
coro_arr_linear_test();

//!#gmcr*/
