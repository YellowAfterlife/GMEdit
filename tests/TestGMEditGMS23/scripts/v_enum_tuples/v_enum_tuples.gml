function v_enum_tuples() {
	var et/*:enum_tuple<v_enum_tuple>*/ = [1, "2"];
	et = [1, 2]; ///want_warn
	et[v_enum_tuple.an_int] = "1"; ///want_warn
	et[v_enum_tuple.an_int] = 1;
	et[v_enum_tuple.a_string] = 2; ///want_warn
	et[v_enum_tuple.a_string] = "2";
	
	// but also:
	var et2/*:v_enum_tuple*/ = array_create(v_enum_tuple.sizeof);
	et2[@v_enum_tuple.an_int] = 1;
	et2[@v_enum_tuple.an_int] = "1"; ///want_warn
	et2[@v_enum_tuple.a_string] = "hi";
	et2[@v_enum_tuple.a_string] = 2; ///want_warn
}
enum v_enum_tuple {
	an_int, /// @is {int}
	a_string, /// @is {string}
	sizeof
}