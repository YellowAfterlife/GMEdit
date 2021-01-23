function v_null_conditional() {
	var zi/*:int?*/ = 0;
	var i/*:int*/, s/*:string*/;
	i = zi; // want warn
	i = zi != undefined ? zi : 0; // want warn (ideally not, but this is where we are)
	i = zi != undefined ? zi /*#as int*/ : 0;
	i = nc_set(zi) ? nc_val : 0;
	i = nc_set(zi) ? nc_val : ""; // want warn
	i = nc_set(zi) ? nc_val : zi; // want warn
}