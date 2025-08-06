/// @param {int} a
function v_doc_both() {
	/// @param {string} b
}
if (false) {
	v_doc_both(); ///want_warn
	v_doc_both(1); ///want_warn
	v_doc_both(1, ""); ///note: OK!
	v_doc_both(""); ///want_warn
	v_doc_both(1, 2); ///want_warn
}