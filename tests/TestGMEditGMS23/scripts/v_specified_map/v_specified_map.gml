function v_specified_map() {
	var m/*:specified_map<a:int, b:string, void>*/;
	m = ds_map_create(); ///note: allowed
	m = []; ///want_warn
	m[?"a"] = 1;
	m[?"a"] = "1"; ///want_warn
	m[?"b"] = "hi";
	m[?"b"] = 2; ///want_warn
	m[?"c"] = 3; ///want_warn - missing field
}