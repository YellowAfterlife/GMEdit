globalvar g_one; g_one = 1; /// @is {int}
global.two = 2; /// @is {int}
#macro m_two global.two
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
	i = m_two;
	s = m_two; // want warn
	m_two = i;
	m_two = s; // want warn
}