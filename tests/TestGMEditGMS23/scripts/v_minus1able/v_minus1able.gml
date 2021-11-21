function v_minus1able() {
	let list = ds_list_create();
	list = 0; ///want_warn
	list = -1;
	list = -2; ///want_warn
	list = (-1);
	list = -(1);
	list = - - - 1;
	
	let map/*:ds_map<ds_list, bool>*/ = -1;
	map[?list] = true;
	map[?-1] = true;
	map[?0] = true; ///want_warn
	
	let res/*:asset*/ = -1;
	let spr/*:sprite*/ = -1;
	
	vertex_submit(-1, pr_linelist, -1); ///note: OK!
}