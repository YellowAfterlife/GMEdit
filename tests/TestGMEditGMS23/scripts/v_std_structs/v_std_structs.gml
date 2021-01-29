function v_std_structs() {
	exception_unhandled_handler(function() {}) // want warn - no arg
	exception_unhandled_handler(function(z/*:string*/) {}) // want warn - wrong arg
	exception_unhandled_handler(function(e/*:Exception*/) {
		show_message("Trouble!" + e.message);
		show_message("Trouble!" + e.miss); // want warn
	})
}