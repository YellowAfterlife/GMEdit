function coro_comments() {
	return new coro_comments_coroutine();
}
function coro_comments_coroutine() constructor {
	__label__ = 0;
	result = undefined;
	static next = function() {
		while (true) switch (__label__) {
		case 0/* [L6,c26] begin */:
			result = 1; __label__ = 1; return true;
		case 1/* [L8,c2] post yield */:
			s = "looks kind of silly with some GMEdit syntax extensions";
		default/* [L10,c1] end */: result = undefined; return false;
		}
	}
}

// @gmcr {"mode":"constructor","yieldScripts":["coro_comments"]}

/*//!#gmcr
#gmcr
/**
since your code goes in a multi-line comment,
we have to be careful not to break that comment
**\endco\/
function coro_comments() {
	/* here's another one *\endco\/
	yield 1;
	var s/*:string*\endco\/ = "looks kind of silly with some GMEdit syntax extensions";
}
//!#gmcr*/
