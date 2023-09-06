coro_test_m();
function coro_jump_m(n, k) {
	var l_label = 0;
	while (true) switch (l_label) {
		case 0/* [L2,c28] begin */:
		var i = 0;
	case 1/* [L4,c2] check for */:
		if (i >= argument0) { l_label = 3; continue; }
		if (i == argument1) { l_label = 4/* done */; continue; }
	case 2/* [L4,c2] post for */:
		i++;
		l_label = 1; continue;
	case 3/* [L4,c2] end for */:
	case 4/* [L7,c2] done */:
		return i;
	default/* [L15,c14] end */: exit;
	}
}

function coro_test_m() {
	assert(coro_jump_m(5, 3), 3, "coro_jump");
	trace("Coroutines OK!");
}

// @gmcr {"mode":"constructor","yieldScripts":[]}

/*//!#gmcr
#gmcr
function coro_jump_m(n, k) {
	var i = 0;
	for (; i < n; i++) {
		if (i == k) goto done;
	}
	label done:
	return i;
}
function coro_test_m() {
	assert(coro_jump_m(5, 3), 3, "coro_jump")
	
	trace("Coroutines OK!");
}
coro_test_m();
//!#gmcr*/
