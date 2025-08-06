/// @param {int} a
function v_doc_outside() {
	//
}
if (false) {
	v_doc_outside(); ///want_warn
	v_doc_outside(1); ///note: OK!
	v_doc_outside(""); ///want_warn
	v_doc_outside(1, 2); ///want_warn
}
