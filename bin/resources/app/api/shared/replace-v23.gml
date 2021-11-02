//////////////
// Chapter 402
//////////////

#region 2.2

is_struct(val:any)->bool
is_method(val:any)->bool
instanceof<T:struct>(struct:T)->string|undefined
exception_unhandled_handler(user_handler:function<Exception;any|void>)

variable_struct_exists<T:struct>(struct:T,name:string)->bool
variable_struct_get<T:struct>(struct:T,name:string)->any
variable_struct_set<T:struct>(struct:T,name:string,val:any)->void
variable_struct_get_names<T:struct>(struct:T)->string[]
variable_struct_names_count<T:struct>(struct:T)->int
variable_struct_remove<T:struct>(struct:T,name:string)->void
array_length<T>(variable:T[])->int
array_length_1d<T>(variable:T[])&->int
array_length_2d<T>(variable:T[], index:int)&->int
array_height_2d<T>(variable:T[])&->int
array_resize<T>(variable:T[],newsize:int)->void
array_push<T>(array:T[],...values:T)->void
array_pop<T>(array:T[])->T
array_insert<T>(array:T[],index:int,...values:T)->void
array_delete<T>(array:T[],index:int,number:int)->void
array_sort<T>(array:T[],sortType_or_function:bool|function<T;T;int>)->void

weak_ref_create<T:struct>(thing_to_track:T)->weak_reference
weak_ref_alive(weak_ref:weak_reference)->bool
weak_ref_any_alive(array:weak_reference[],?index:int,?length:int)->bool

#endregion

#region 2.3

method<T:function>(context:instance|struct|undefined,func:T)->T
method_get_index(method)
method_get_self(method)

string_pos_ext(substr:string,str:string,startpos:int)->int
string_last_pos(substr:string,str:string)->int
string_last_pos_ext(substr:string,str:string,startpos:int)->int

#endregion

//////////////
// Chapter 403
//////////////

#region 3.9

// long-gone variables:
show_score&
show_lives&
show_health&
caption_score&
caption_lives&
caption_health&

#endregion

#region 3.11

debug_get_callstack(?maxDepth:int)->string[]
font_texture_page_size:int

#endregion

//////////////
// Chapter 405
//////////////

#region 5.1

// exception structure entries
[+message]??Exception
message?:string
longMessage?:string
script?:script
stacktrace?:string[]

// Sequence-related built-ins
in_sequence@:bool
sequence_instance@ //TODO

#endregion

//////////////
// Chapter 406
//////////////

audio_system()&->void

//////////////
// Chapter 407
//////////////

//////////////
// Chapter 408
//////////////

//////////////
// Chapter 409
//////////////

#region 9.6

script_execute_ext(ind:script,args:any[],offset:int=0,num_args:int=args_length-offset)->any

#endregion

#region 9.9

asset_sequence#:asset_type
asset_animationcurve#:asset_type

#endregion

//////////////
// Chapter 410
//////////////

//////////////
// Chapter 411
//////////////

#region 11.3 - list

ds_list_is_map<T>(list:ds_list<T>, pos:int)->bool
ds_list_is_list<T>(list:ds_list<T>, pos:int)->bool

#endregion

#region 11.4 - map

ds_map_keys_to_array<K;V>(map:ds_map<K;V>, ?K[])->K[]
ds_map_values_to_array<K;V>(map:ds_map<K;V>, ?V[])->V[]
ds_map_is_map<K;V>(map:ds_map<K;V>,key:K)->bool
ds_map_is_list<K;V>(map:ds_map<K;V>,key:K)->bool

#endregion

//////////////
// Chapter 412
//////////////


//////////////
// Chapter 414
//////////////

//////////////
// Chapter 415
//////////////

event_data*:ds_map<string,any>

json_stringify<T:struct|array|number|string|undefined>(val:T)->string
json_parse(json:string)->any

network_socket_ws#:network_type
network_config_avoid_time_wait#:network_config
buffer_surface_copy&:any
buffer_get_surface(buffer:buffer, surface:surface,offset:int)->void
buffer_set_surface(buffer:buffer, surface:surface,offset:int)->void


//tags
tag_get_asset_ids(tags:string|string[],asset_type:asset_type)->asset[]
tag_get_assets(tags:string|string[])->string[]
asset_get_tags(asset_name_or_id:string|asset,?asset_type:asset_type)->string[]
asset_add_tags(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_remove_tags(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_has_tags(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_has_any_tag(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_clear_tags(asset_name_or_id:string|asset,?asset_type:asset_type)->bool


//extension_get_string(ext_name:string, option_name:string)->any




//sequences
layer_sequence_get_instance(sequence_element_id:layer_sequence)->any // TODO
layer_sequence_create(layer_id:layer|string,x:number,y:number,sequence_id:sequence)->layer_sequence
layer_sequence_destroy(sequence_element_id:layer_sequence)->void
layer_sequence_exists(layer_id:layer|string,sequence_element_id:layer_sequence)->bool
layer_sequence_x(sequence_element_id:layer_sequence,pos_x:number)->void
layer_sequence_y(sequence_element_id:layer_sequence,pos_y:number)->void
layer_sequence_angle(sequence_element_id:layer_sequence,angle:number)->void
layer_sequence_xscale(sequence_element_id:layer_sequence,xscale:number)->void
layer_sequence_yscale(sequence_element_id:layer_sequence,yscale:number)->void
layer_sequence_headpos(sequence_element_id:layer_sequence,position:number)->void
layer_sequence_headdir(sequence_element_id:layer_sequence,direction:number)->void
layer_sequence_pause(sequence_element_id:layer_sequence)->void
layer_sequence_play(sequence_element_id:layer_sequence)->void
layer_sequence_speedscale(sequence_element_id:layer_sequence,speedscale:number)->void

layer_sequence_get_x(sequence_element_id:layer_sequence)->number
layer_sequence_get_y(sequence_element_id:layer_sequence)->number
layer_sequence_get_angle(sequence_element_id:layer_sequence)->number
layer_sequence_get_xscale(sequence_element_id:layer_sequence)->number
layer_sequence_get_yscale(sequence_element_id:layer_sequence)->number
layer_sequence_get_headpos(sequence_element_id:layer_sequence)->number
layer_sequence_get_headdir(sequence_element_id:layer_sequence)->number
layer_sequence_get_sequence(sequence_element_id:layer_sequence)->any // TODO
layer_sequence_is_paused(sequence_element_id:layer_sequence)->bool
layer_sequence_is_finished(sequence_element_id:layer_sequence)->bool
layer_sequence_get_speedscale(sequence_element_id:layer_sequence)->number

layer_sequence_get_length(sequence_element_id:layer_sequence)->int


// All sequence functions omitted


// Garbage collection functions
gc_collect()->void
gc_enable(enable:bool)->void
gc_is_enabled()->bool

// This actually returns GCStats as defined below, by the original fnames
gc_get_stats()->any // where any:struct


gc_target_frame_time(time:int)->void
gc_get_target_frame_time()->int

// Garbage collection stats structure members
??GCStats
objects_touched?:int
objects_collected?:int
traversal_time?:int
collection_time?:int
gc_frame?:int
generation_collected?:int
num_generations?:int
num_objects_in_generation?:int

