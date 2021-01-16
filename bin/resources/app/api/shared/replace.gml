script_execute(script, ...arguments)
mean(...values:number)->number
choose<T>(...values:T)->T
median(...values:number)->number
min(...values:number)->number
max(...values:number)->number

is_bool(val)->bool
is_real(val)->bool
is_string(val)->bool
is_array(val)->bool
is_undefined(val)->bool
is_int32(val)->bool
is_int64(val)->bool
is_ptr(val)->bool

dll_cdecl#:dll_t
dll_stdcall#:dll_t
ty_real#:ty_t
ty_string#:ty_t
external_define(dll_name:string, func_name:string, calltype:dll_t, restype:ty_t, argnumb:number, ...argtypes:ty_t)->external_function
external_call(func:external_function, ...arguments)
