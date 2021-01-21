function get_1()/*->int*/ {
	return 1;
}
function get_a1()/*->array<int>*/ {
	return [2];
}
function v_imp_return_type() {
	var v/*:string*/ = get_1(); // want warning
}