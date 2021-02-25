// this tests both the #import saving tag-comments correctly and linter
function Some(a/*:int*/, b/*:int*/) constructor {
	a = ""; ///want_warn
	static sub = function(c/*:string*/) {
		c = 0; ///want_warn
	}
}

function v_imp_func_args() {
	var s = new Some("", 0); ///want_warn
}