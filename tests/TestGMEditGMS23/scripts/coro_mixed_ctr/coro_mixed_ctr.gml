// mixing different coroutine types in one script is (unfortunately) allowed
function coro_mixed_ctr() {
	return new coro_mixed_ctr_coroutine();
}
function coro_mixed_ctr_coroutine() constructor {
	__label__ = 0;
	result = undefined;
	static next = function() {
		while (true) switch (__label__) {
		case 0/* [L3,c27] begin */:
			result = 1; __label__ = 1; return true;
		case 1/* [L4,c2] post yield */:
		default/* [L27,c0] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_mixed_ctr_goto() {
	var l_label = 0;
	while (true) switch (l_label) {
	case 0/* [L6,c32] begin */:
		l_label = 1/* A */; continue;
		return "no";
	case 1/* [L10,c2] A */:
		return "yeah";
	default/* [L27,c0] end */:
		exit;
	}
}

function coro_mixed_ctr_simple() {
	return "OK";
}

function coro_mixed_ctr_test() {
	var c = coro_mixed_ctr();
	assert(c.next(), 1);
	assert(c.result, 1);
	var g = coro_mixed_ctr_goto();
	assert(g, "yeah");
	var s = coro_mixed_ctr_simple();
	assert(s, "OK");
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_mixed_ctr"]}

/*//!#gmcr
#gmcr
// mixing different coroutine types in one script is (unfortunately) allowed
function coro_mixed_ctr() {
	yield 1;
}
function coro_mixed_ctr_goto() {
	goto A;
	return "no";
	
	label A:
	return "yeah";
}
function coro_mixed_ctr_simple() {
	return "OK";
}
function coro_mixed_ctr_test() {
	var c := coro_mixed_ctr();
	assert(c.next(), true);
	assert(c.result, 1);
	
	var g := coro_mixed_ctr_goto();
	assert(g, "yeah");
	
	var s := coro_mixed_ctr_simple();
	assert(s, "OK");
}

//!#gmcr*/
