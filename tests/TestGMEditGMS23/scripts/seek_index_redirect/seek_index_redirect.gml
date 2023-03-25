function setTimeout() {}
function seek_index_redirect() {
	let f1 = function(a/*:int*/) {}
	setTimeout_1(f1, 0, 1);
	setTimeout_1(f1, 0, ""); ///want_warn - wrong argument type
	setTimeout_1(f1, 0, 1, 2); ///want_warn - too many arguments
	let f2 = function(i/*:int*/, s/*:string*/) {}
	setTimeout_2(f2, 0, 1, "hi");
	setTimeout_2(f2, 0, 1, 2); ///want_warn - wrong argument type
	setTimeout_2(f2, 0, 1); ///want_warn - not enough arguments
}
/// @index_redirect /notes/seek_index_redirect_note/seek_index_redirect_note.txt
#macro setTimeout_1 setTimeout
#macro setTimeout_2 setTimeout