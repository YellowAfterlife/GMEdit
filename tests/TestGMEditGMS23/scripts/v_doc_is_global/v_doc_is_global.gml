globalvar g_one; g_one = 1; /// @is {int}
global.two = 2; /// @is {int}
function v_doc_is_global() {
	var i/*:int*/, s/*:string*/;
	i = g_one;
	s = g_one; // want warn
	g_one = i;
	g_one = s; // want warn
	i = global.two; 
	s = global.two; // want warn
	global.two = i;
	global.two = s; // want warn
}