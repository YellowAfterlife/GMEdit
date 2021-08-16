a_func(); ///want_warn "Not enough arguments for a_func"

with (obj_self_object) {
	with (noone) {
		// (nothing)
	}
	field = 0; ///note: should not warn
}