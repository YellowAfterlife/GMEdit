function v_speculative_types() {
	let i = 1;
	i = ""; // want warn - mismatch
	if (1) {
		let a = [];
		let b = {v:1};
	}
	if (1) {
		let a = undefined; // want warn - redefinition
		let b;
	}
}