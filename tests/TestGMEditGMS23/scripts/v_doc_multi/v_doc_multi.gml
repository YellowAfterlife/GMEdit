/**
	@param {int} a
	@param {string} b
**/
function v_doc_multi_1(a, b) {
	
}
/**
 * @param {int} a
 * @param {string} b
 */
function v_doc_multi_2(a, b) {
	
}
function v_doc_multi() {
	v_doc_multi_1(1, "");
	v_doc_multi_1("", 2); ///want_warn
	v_doc_multi_2(1, "");
	v_doc_multi_2("", 2); ///want_warn
}