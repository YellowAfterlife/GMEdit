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

// section 11.0

ds_set_precision(prec:number)
ds_exists(id, type:ds_type)->bool

ds_type_map#:ds_type
ds_type_list#:ds_type
ds_type_stack#:ds_type
ds_type_queue#:ds_type
ds_type_grid#:ds_type
ds_type_priority#:ds_type

// section 11.3 / list
ds_list_create()->ds_list
ds_list_destroy<T>(list:ds_list<T>)
ds_list_clear<T>(list:ds_list<T>)
ds_list_copy<T>(list:ds_list<T>, source:ds_list<T>)
ds_list_size<T>(list:ds_list<T>)->int
ds_list_empty<T>(list:ds_list<T>)->bool
ds_list_add<T>(list:ds_list<T>, ...values:T)
ds_list_insert<T>(list:ds_list<T>, pos:int, value:T)
ds_list_replace<T>(list:ds_list<T>, pos:int, value:T)
ds_list_delete<T>(list:ds_list<T>, pos:int)
ds_list_find_index<T>(list:ds_list<T>, value:T)->int
ds_list_find_value<T>(list:ds_list<T>, pos:int)->T
ds_list_is_map<T>(list:ds_list<T>, pos:int)->bool
ds_list_is_list<T>(list:ds_list<T>, pos:int)->bool
ds_list_mark_as_list<T>(list:ds_list<T>,pos:int)
ds_list_mark_as_map<T>(list:ds_list<T>,pos:int)
ds_list_sort<T>(list:ds_list<T>,ascending:bool)
ds_list_shuffle<T>(list:ds_list<T>)
ds_list_write<T>(list:ds_list<T>)->string
ds_list_read<T>(list:ds_list<T>, str:string, ?legacy:bool)
ds_list_set<T>(list:ds_list<T>,pos:int,value:T)

// section 11.4 / map
ds_map_create()->ds_map
ds_map_destroy<K;V>(map:ds_map<K;V>)
ds_map_clear<K;V>(map:ds_map<K;V>)
ds_map_copy<K;V>(map:ds_map<K;V>, source:ds_map<K;V>)
ds_map_size<K;V>(map:ds_map<K;V>)->int
ds_map_empty<K;V>(map:ds_map<K;V>)->bool
ds_map_add<K;V>(map:ds_map<K;V>,key:K,value:V)->bool
ds_map_add_list<K;V>(map:ds_map<K;V>,key:K,value:V)
ds_map_add_map<K;V>(map:ds_map<K;V>,key:K,value:V)
ds_map_replace<K;V>(map:ds_map<K;V>,key:K,value:V)->bool
ds_map_replace_map<K;V>(map:ds_map<K;V>,key:K,value:V)
ds_map_replace_list<K;V>(map:ds_map<K;V>,key:K,value:V)
ds_map_delete<K;V>(map:ds_map<K;V>,key:K)
ds_map_exists<K;V>(map:ds_map<K;V>,key:K)->bool
ds_map_find_value<K;V>(map:ds_map<K;V>,key)->V
ds_map_find_previous<K;V>(map:ds_map<K;V>,key:K)->K
ds_map_find_next<K;V>(map:ds_map<K;V>,key:K)->K
ds_map_find_first<K;V>(map:ds_map<K;V>)->K
ds_map_find_last<K;V>(map:ds_map<K;V>)->K
ds_map_write<K;V>(map:ds_map<K;V>)->string
ds_map_read<K;V>(map:ds_map<K;V>, str:string, ?legacy:bool)
ds_map_set<K;V>(map:ds_map<K;V>,key:K,value:V)

ds_map_secure_save<K;V>(map:ds_map<K;V>, filename:string)
ds_map_secure_load<K;V>(filename:string)->ds_map<K;V>
ds_map_secure_load_buffer<K;V>(buffer:buffer)->ds_map<K;V>
ds_map_secure_save_buffer<K;V>(map:ds_map<K;V>,buffer:buffer)->ds_map<K;V>

// section 11.6 / grid
ds_grid_create(w:int,h:int):ds_grid
ds_grid_destroy<T>(grid:ds_grid<T>)
ds_grid_copy<T>(grid:ds_grid<T>, source:ds_grid<T>)
ds_grid_resize<T>(grid:ds_grid<T>, w:int, h:int)
ds_grid_width<T>(grid:ds_grid<T>)->int
ds_grid_height<T>(grid:ds_grid<T>)->int
ds_grid_clear<T>(grid:ds_grid<T>, val:T)
ds_grid_add<T>(grid:ds_grid<T>,x:int,y:int,val:T)
ds_grid_multiply<T>(grid:ds_grid<T>,x:int,y:int,val:T)

ds_grid_set_region<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)
ds_grid_add_region<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)
ds_grid_multiply_region<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)
ds_grid_set_disk<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)
ds_grid_add_disk<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)
ds_grid_multiply_disk<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)
ds_grid_set_grid_region<T>(grid:ds_grid<T>,source,x1:int,y1:int,x2:int,y2:int,xpos,ypos)
ds_grid_add_grid_region<T>(grid:ds_grid<T>,source,x1:int,y1:int,x2:int,y2:int,xpos,ypos)
ds_grid_multiply_grid_region<T>(grid:ds_grid<T>,source,x1:int,y1:int,x2:int,y2:int,xpos,ypos)

ds_grid_get_sum<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int)->T
ds_grid_get_max<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int)->T
ds_grid_get_min<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int)->T
ds_grid_get_mean<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int)->T
ds_grid_get_disk_sum<T>(grid:ds_grid<T>,xm:number,ym:number,r:number)->T
ds_grid_get_disk_min<T>(grid:ds_grid<T>,xm:number,ym:number,r:number)->T
ds_grid_get_disk_max<T>(grid:ds_grid<T>,xm:number,ym:number,r:number)->T
ds_grid_get_disk_mean<T>(grid:ds_grid<T>,xm:number,ym:number,r:number)->T

ds_grid_value_exists<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)->bool
ds_grid_value_x<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)->int
ds_grid_value_y<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)->int
ds_grid_value_disk_exists<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)->bool
ds_grid_value_disk_x<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)->int
ds_grid_value_disk_y<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)->int
ds_grid_shuffle<T>(grid:ds_grid<T>)

ds_grid_write<T>(grid:ds_grid<T>)->string
ds_grid_read<T>(grid:ds_grid<T>, str:string, ?legacy:bool)

ds_grid_sort<T>(grid:ds_grid<T>, column:int, ascending:bool)
ds_grid_set<T>(grid:ds_grid<T>, x:int, y:int, value:T)
ds_grid_get<T>(grid:ds_grid<T>, x:int, y)
