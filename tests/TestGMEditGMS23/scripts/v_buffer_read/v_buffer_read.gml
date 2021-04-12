function v_buffer_read() {
	let b = buffer_create(32, buffer_fixed, 1);
	var i/*:int*/, s/*:string*/;
	
	buffer_write(b, buffer_s32, i);
	buffer_write(b, buffer_s32, s); ///want_warn
	
	buffer_write(b, buffer_string, i); ///want_warn
	buffer_write(b, buffer_string, s);
	
	buffer_poke(b, 0, buffer_s32, i);
	buffer_poke(b, 0, buffer_s32, s); ///want_warn
	
	buffer_poke(b, 0, buffer_string, i); ///want_warn
	buffer_poke(b, 0, buffer_string, s);
	
	i = buffer_read(b, buffer_s32);
	s = buffer_read(b, buffer_s32); ///want_warn
	
	i = buffer_read(b, buffer_f64);
	s = buffer_read(b, buffer_f64); ///want_warn
	
	i = buffer_read(b, buffer_string); ///want_warn
	s = buffer_read(b, buffer_string);
	
	s = buffer_peek(b, 0, buffer_s32); ///want_warn
	
	buffer_fill(b, 0, buffer_s32, i, 4);
	buffer_fill(b, 0, buffer_s32, s, 4); ///want_warn
	
	buffer_fill(b, 0, buffer_string, i, 4); ///want_warn
	buffer_fill(b, 0, buffer_string, s, 4);
}