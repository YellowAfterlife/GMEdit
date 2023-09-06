// in constructor mode, coroutines will be auto-bind self/other if used
coro_self_test();
function coro_self() {
	return new coro_self_coroutine(self);
}
function coro_self_coroutine(_self) constructor {
	__label__ = 0;
	result = undefined;
	__self__ = _self;
	static next = function() {
		while (true) switch (__label__) {
		case 0/* [L3,c22] begin */:
			result = __self__.name; __label__ = 1; return true;
		case 1/* [L4,c2] post yield */:
		default/* [L29,c17] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_other() {
	return new coro_other_coroutine(other);
}
function coro_other_coroutine(_other) constructor {
	__label__ = 0;
	result = undefined;
	__other__ = _other;
	static next = function() {
		while (true) switch (__label__) {
		case 0/* [L6,c23] begin */:
			result = __other__.name; __label__ = 1; return true;
		case 1/* [L7,c2] post yield */:
		default/* [L29,c17] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_self_other() {
	return new coro_self_other_coroutine(self, other);
}
function coro_self_other_coroutine(_self, _other) constructor {
	__label__ = 0;
	result = undefined;
	__self__ = _self;
	__other__ = _other;
	static next = function() {
		while (true) switch (__label__) {
		case 0/* [L9,c28] begin */:
			result = [__self__.name, __other__.name]; __label__ = 1; return true;
		case 1/* [L10,c2] post yield */:
		default/* [L29,c17] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_self_test() {
	with ({ name: "test" }) {
		var c1 = coro_self();
		assert(c1.next(), 1);
		assert(c1.result, "test");
		with ({ }) {
			var c2 = coro_other();
			assert(c2.next(), 1);
			assert(c2.result, "test");
			var c3 = coro_other();
			assert(c3.next(), 1);
			assert(c3.result, "test");
		}
	}
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_self","coro_other","coro_self_other"]}

/*//!#gmcr
#gmcr
// in constructor mode, coroutines will be auto-bind self/other if used
function coro_self() {
	yield self.name;
}
function coro_other() {
	yield other.name;
}
function coro_self_other() {
	yield [self.name, other.name];
}
function coro_self_test() {
	with ({ name: "test" }) {
		var c1 := coro_self();
		assert(c1.next(), true);
		assert(c1.result, "test");
		with ({}) {
			var c2 := coro_other();
			assert(c2.next(), true);
			assert(c2.result, "test");
			
			var c3 := coro_other();
			assert(c3.next(), true);
			assert(c3.result, "test");
		}
	}
	
}
coro_self_test();
//!#gmcr*/
