/// @param {buffer} buf
/// @param {string} name
/// @param {buffer_type} type
/// @param {buffer_auto_type} value
function v_buffer_auto_type_dump(buf, name, type, val) {
	//
}
function v_buffer_auto_type() {
	let b = buffer_create(16, buffer_grow, 1);
	v_buffer_auto_type_dump(b, "one", buffer_f64, 1);
	v_buffer_auto_type_dump(b, "one", buffer_f64, ""); ///want_warn
	v_buffer_auto_type_dump(b, "one", buffer_u8, 1);
	v_buffer_auto_type_dump(b, "one", buffer_u8, ""); ///want_warn
	v_buffer_auto_type_dump(b, "one", buffer_string, "");
	v_buffer_auto_type_dump(b, "one", buffer_string, 1); ///want_warn
}