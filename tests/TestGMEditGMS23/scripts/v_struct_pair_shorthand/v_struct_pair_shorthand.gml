function v_struct_pair_shorthand() {
	let i = 1;
	let s = "";
	let q = {i, k: 1, s};
	q.i += 1;
	q.i += ""; ///want_warn
	q.k += 1;
	q.k += ""; ///want_warn
	q.s += "";
	q.s += 1; ///want_warn
}