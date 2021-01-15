argument_relative*&
instance_destroy(?id, ?execute_destroy_event)
script_execute(script, ...arguments)
mean(...values:number)->number
choose<T>(...values:T)->T
median(...values:number)->number
min(...values:number)->number
max(...values:number)->number

dll_cdecl#:external_calltype
dll_stdcall#:external_calltype
ty_real#:external_restype
ty_string#:external_restype
external_define(dll_name:string, func_name:string, calltype:external_calltype, restype:external_restype, argnumb:number, ...argtypes)->external_func
external_call(func:external_func, ...arguments)
