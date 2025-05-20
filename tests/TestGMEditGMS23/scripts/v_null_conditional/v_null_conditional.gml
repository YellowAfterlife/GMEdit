function v_null_conditional() {
	var zi/*:int?*/ = 0;
	var i/*:int*/, s/*:string*/;
	i = zi; ///want_warn
	i = zi != undefined ? zi : 0;
	i = nc_set(zi) ? nc_val : 0;
	i = nc_set(zi) ? nc_val : ""; ///want_warn
	i = nc_set(zi) ? nc_val : zi; ///want_warn
}