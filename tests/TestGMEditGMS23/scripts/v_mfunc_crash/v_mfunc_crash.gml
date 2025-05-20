// brackets matter
//!#mfunc some_index_inline {"args":["index"],"order":[0]}
#macro some_index_inline_mf0  some_arr[
#macro some_index_inline_mf1 ]
function v_mfunc_crash() {
	var some_arr = [];
	if (some_index_inline_mf0 1 some_index_inline_mf1) {
	    //
	}
}