coro_with_test();
function coro_with(ctx) {
	var l_argc = argument_count;
	var l_args = array_create(l_argc);
	while (--l_argc >= 0) l_args[l_argc] = argument[l_argc];
	return new coro_with_coroutine(l_args);
}
function coro_with_coroutine(_args) constructor {
	__label__ = 0;
	result = undefined;
	__argument__ = _args;
	static next = function() {
		var __local__ = self;
		while (true) switch (__label__) {
		case 0/* [L2,c25] begin */:
			with (__argument__[0]) {
				other._x = self.x;
				other._y = self.y;
				with (other.__argument__[0]) {
					__local__._x2 = self.x;
					__local__._y2 = self.y;
					with (__local__.__argument__[0]) {
						__local__._x3 = self.x;
						__local__._y3 = self.y;
					}
				}
			}
			result = [_x, _y, _x2, _y2, _x3, _y3]; __label__ = 1; return true;
		case 1/* [L16,c2] post yield */:
		default/* [L25,c17] end */:
			result = undefined; __label__ = -1; return false;
		}
	}
}

function coro_with_test() {
	var a = 1;
	var ca = coro_with({ x: 1, y: 2 });
	assert(ca.next(), 1);
	assert(ca.result, [1, 2, 1, 2, 1, 2]);
	assert(ca.next(), 0);
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_with"]}

/*//!#gmcr
#gmcr
function coro_with(ctx) {
	var _x, _y, _x2, _y2, _x3, _y3;
	with (ctx) {
		_x = x;
		_y = y;
		with (ctx) {
			_x2 = x;
			_y2 = y;
			with (ctx) {
				_x3 = x;
				_y3 = y;
			}
		}
	}
	yield [_x, _y, _x2, _y2, _x3, _y3];
}
function coro_with_test() {
	var a = 1;
	var ca := coro_with({x:1, y:2});
	assert(ca.next(), true);
	assert(ca.result, [1, 2, 1, 2, 1, 2]);
 	assert(ca.next(), false);
}
coro_with_test();
//!#gmcr*/
