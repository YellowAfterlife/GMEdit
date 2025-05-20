coro_local_test();
function coro_local() {
	return new coro_local_coroutine();
}
function coro_local_coroutine() constructor {
	__label__ = 0;
	result = undefined;
	static next = function() {
		while (true) switch (__label__) {
		case 0/* [L2,c23] begin */:
			a = 1;
			b = 2;
			result = variable_struct_get_names(self); __label__ = 1; return true;
		case 1/* [L4,c2] post yield */:
		default/* [L13,c18] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_local_test() {
	var co = coro_local();
	co.next();
	var names = co.result;
	assert(array_get_index(names, "a") >= 0, 1);
	assert(array_get_index(names, "b") >= 0, 1);
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_local"]}

/*//!#gmcr
#gmcr
function coro_local() {
	var a = 1, b = 2;
	yield variable_struct_get_names(local);
}
function coro_local_test() {
	var co := coro_local();
	co.next();
	var names = co.result;
	assert(array_get_index(names, "a") >= 0, true);
	assert(array_get_index(names, "b") >= 0, true);
}
coro_local_test();
//!#gmcr*/
