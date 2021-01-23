function v_imp_typed_let() {
	let a/*:int*/ = 0;
	a = ""; // want warn
	const b/*:int*/ = 0;
	b = 1; // want warn
}