function v_doc_inside() {
	/// @param {int} b
}
if (false) {
	v_doc_inside(); ///want_warn
	v_doc_inside(1); ///note: OK!
	v_doc_inside(""); ///want_warn
	v_doc_inside(1, 2); ///want_warn
}