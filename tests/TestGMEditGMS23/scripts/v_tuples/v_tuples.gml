function v_tuples() {
	var t/*:[int, string]*/ = [1, "hi"];
	t = [2, "3"];
	t = [1, 2]; ///want_warn
	t = [1]; ///want_warn - too few items
	t = [1, "2", 3]; ///want_warn - too many items
	
	t[0] = 1;
	t[0] = "1"; ///want_warn
	
	t[@0] = 1;
	t[@0] = "1"; ///want_warn
	
	t[2] = 0; ///want_warn
	
	var i/*:int*/, s/*:string*/;
	i = t[0];
	s = t[0]; ///want_warn
	s = t[1];
	i = t[1]; ///want_warn
	
	var tups/*:[int, string][]*/ = [
		[1, "2"],
		[3, 4], ///want_warn
		[5], ///want_warn
	];
	
	var named/*:[x:number, y:number, z:number]*/ = [1, 2, 3];
	// typing `named[` should pop up a menu with field list
	
	var multi/*:[i:int][]*/ = [[1], [2], [3]];
	multi[0][0] = 1;
	multi[0, 0] = 1;
	multi[0][0] = "1"; ///want_warn
	multi[0, 0] = "1"; ///want_warn
	
	var has_array/*:[name:string, arr:int[]]*/ = ["an array", [1, 2, 3]];
	has_array[0] = ":)";
	has_array[0] = 0; ///want_warn
	has_array[0, 0] = 0; ///want_warn
	has_array[1][0] = 0;
	has_array[1, 0] = 0;
	has_array[1][0] = ""; ///want_warn
	has_array[1, 0] = ""; ///want_warn
	
	var has_rest/*:[a:int, b:string, etc:rest<int>]*/;
	has_rest = [1]; ///want_warn
	has_rest = [1, "2"];
	has_rest = [1, 2]; ///want_warn
	has_rest = [1, "2", 3];
	has_rest = [1, "2", "3"]; ///want_warn
	has_rest = [1, "2", 3, 4];
	has_rest = [1, "2", 3, "4"]; ///want_warn
	//has_rest[-1] = 0; ///want_warn
	has_rest[2] = 0;
	has_rest[3] = 0;
	has_rest[4] = ""; ///want_warn
}