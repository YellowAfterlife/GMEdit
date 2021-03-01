// Context: choose() is complicated.
function v_choose() {
	var i/*:number*/ = choose(1, 2, 3);
	var i/*:string*/ = choose(1, 2, 3); ///want_warn "number to string"
	var o/*:object*/ = choose(obj_one /*#as object*/, obj_two); ///note: `as object` required to unify args
}