/**
Kind of quirky, isn't it?

**/

/// @param {int} A
function v_doc_nested() constructor {
	/// @param {string} B
	static fun = function() {
		/// @param {array} C
	}
	/// @param {blendmode} bm
}
if (false) {
	let q = new v_doc_nested(1); ///want_warn
	q = new v_doc_nested(1, bm_add); ///note: OK!
	q = new v_doc_nested(1, ""); ///want_warn
	q = new v_doc_nested(1, bm_add, 2); ///want_warn
	//
	q.fun(""); ///want_warn
	q.fun("", []); ///note: OK!
	q.fun([], []); ///want_warn
	q.fun("", ""); ///want_warn
	q.fun("", [], ""); ///want_warn
}