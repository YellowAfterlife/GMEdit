// starting with GMS2023, you can do ScriptName.staticVar
// I'm just making these add statics to namespaces, which is Generally Alright

function v_func_doc_static_singleton() {
	static num = 1, str = "hi!";
	
	static func = function()/*->int*/ { return 2; }
}

function v_func_doc_static_constructor() constructor {
	static no_jsd = 1;
	
	/// @static
	static num = 1, str = "hi!";
	
	/// @static
	static func = function()/*->int*/ { return 2; }
}
function v_func_doc_static() {
	var f/*:number*/, s/*:string*/;
	
	f = v_func_doc_static_singleton.amiss; ///want_warn
	
	f = v_func_doc_static_singleton.num;
	s = v_func_doc_static_singleton.num; ///want_warn
	
	s = v_func_doc_static_singleton.str;
	f = v_func_doc_static_singleton.str; ///want_warn
	
	f = v_func_doc_static_singleton.func();
	s = v_func_doc_static_singleton.func(); ///want_warn
	
	// this test project is configured to have strict statics in constructors
	f = v_func_doc_static_constructor.no_jsd; ///want_warn
	
	f = v_func_doc_static_constructor.num;
	s = v_func_doc_static_constructor.num; ///want_warn
	
	s = v_func_doc_static_constructor.str;
	f = v_func_doc_static_constructor.str; ///want_warn
	
	f = v_func_doc_static_constructor.func();
	s = v_func_doc_static_constructor.func(); ///want_warn
}