function v_constructor_implicit_types_1() constructor {
	int_map = ds_map_create();
	str_map = ds_map_create();
	
	static kind = "test";
	static magic = undefined; /// @is {string?}
	static int_map_size = function() /*=>*/ {return ds_map_size(int_map)};
	static merge = function(thing) {}
	///note: `self.`/`.` should bring up the above
}
function v_constructor_implicit_types_2() : v_constructor_implicit_types_1() constructor {
	int_map[?1] = 2;
	int_map[?""] = ""; ///want_warn
	str_map[?""] = "";
	str_map[?0] = 0; ///want_warn
	
	int_map2 = ds_map_create();
	int_map2[?1] = 2;
	int_map2[?""] = ""; ///want_warn
	
	int_map3 = ds_map_create(); /// @is {ds_map<int, int>}
	int_map3[?1] = 2;
	int_map3[?""] = ""; ///want_warn
}