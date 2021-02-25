globalvar g_one; g_one = 1; /// @is {int}
global.two = 2; /// @is {int}
#macro m_two global.two
function v_doc_is_global() {
	var i/*:int*/, s/*:string*/;
	i = g_one;
	s = g_one; ///want_warn
	g_one = i;
	g_one = s; ///want_warn
	i = global.two; 
	s = global.two; ///want_warn
	global.two = i;
	global.two = s; ///want_warn
	i = m_two;
	s = m_two; ///want_warn
	m_two = i;
	m_two = s; ///want_warn
}