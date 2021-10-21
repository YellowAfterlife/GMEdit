function v_speculative_types() {
	let i = 1;
	i = ""; ///want_warn - mismatch
	if (1) {
		let a = [];
		let b = {v:1};
	}
	if (1) {
		let a = undefined; ///want_warn - redefinition
		let b;
	}
	
	var cq := 2;
	cq = ""; ///want_warn - mismatch
}