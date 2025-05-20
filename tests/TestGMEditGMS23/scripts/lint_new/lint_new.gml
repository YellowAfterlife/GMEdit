function lint_new_ctr(name/*:string*/) constructor {
	static chain = function()/*->lint_new_ctr*/ {
		return self;
	}
	static close = function()/*->void*/ {}
}
function lint_new() {
	let s = "me!", q/*:lint_new_ctr*/;
	
	q = new lint_new_ctr(s);
	q = new lint_new_ctr(s).chain();
	q = new lint_new_ctr(s).chain().chain();
	q = new lint_new_ctr(s).chain().chain().close(); ///want_warn
	q = new lint_new_ctr(s) + 1; ///want_warn
}