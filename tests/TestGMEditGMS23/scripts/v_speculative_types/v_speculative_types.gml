function v_speculative_types() {
	let i = 1;
	i = ""; ///want_warn - mismatch
	if (true) {
		let a = [];
		let b = {v:1};
	}
	
	var cq := 2;
	cq = ""; ///want_warn - mismatch
}