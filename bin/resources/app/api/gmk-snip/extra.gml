trace(...values):
sniptools_show_debug_message(text)

snippet_execute_string(gml_code:string, ...arguments)->any
snippet_define(name:string, gml_code:string)
snippet_define_raw(name:string, raw_gml_code:string)
snippet_exists(name:string)->bool
snippet_get_code(name:string)->string
snippet_call(name:string, ...arguments)->any
snippet_call_ext(name:string, argument_list:ds_list, offset:int=0, ?count:int)->any

snippet_define_object(name:string, gml_code:string)->object
snippet_object_get_name(object_index:object)->string
snippet_object_get_index(object_name:string)->object

snippet_load_list(list:ds_list, dir:string)
snippet_load_listfile(path:string)

snippet_event_get_type(name:string)->int
snippet_event_get_number(name:string)->int
snippet_event_get_number_object(name:string)->string
snippet_event_register(name:string, type:int, number:int)
snippet_event_register_type(name:string, type:int, arg_kind:int)

snippet_function_add(name:string)
snippet_function_remove(name:string)
snippet_parse_api_entry(line:string)
snippet_parse_api_file(path:string)

sniptools_file_exists(full_path:string)->bool
sniptools_file_get_contents(full_path:string)->string

sniptools_string_trim(str:string)->string
sniptools_string_trim_start(str:string)->string
sniptools_string_trim_end(str:string)->string
sniptools_string_is_ident(str:string)->bool
sniptools_string_split_start(str:string)->int
sniptools_string_split_next()->string
