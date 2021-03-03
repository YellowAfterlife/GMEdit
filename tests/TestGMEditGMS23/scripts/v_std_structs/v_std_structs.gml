// Context: testing built-in structure definitions (Type?, ?field)
function v_std_structs() {
	exception_unhandled_handler(function() {}) ///want_warn - no arg
	exception_unhandled_handler(function(z/*:string*/) {}) ///want_warn - wrong arg
	exception_unhandled_handler(function(e/*:Exception*/) {
		show_message("Trouble!" + e.message);
		show_message("Trouble!" + e.miss); ///want_warn
	})
}