//////////////
// Chapter 402
//////////////

instance_create_depth<T:object>(x:number,y:number,depth:number,obj:T,?vars:any_fields_of<T>)->T
instance_create_layer<T:object>(x:number,y:number,layer_id_or_name:layer|string,obj:T,?vars:any_fields_of<T>)->T

#region 2.1

GM_project_filename#:string
GM_build_type#:string
GM_is_sandboxed#:bool
_GMLINE_#:int
_GMFILE_#:string
_GMFUNCTION_#:string
nameof(name:any)->string

#endregion

#region 2.2

is_struct(val:any)->bool
is_method(val:any)->bool
is_instanceof<T:struct>(struct:T, constructor_name:constructor)->bool
is_callable(val:any)->bool
is_handle(val:any)->bool
static_get(struct_or_func_name:struct|function)->struct|undefined
static_set(struct:struct, static_struct:struct)->void
instanceof<T:struct>(struct:T)->string|undefined
exception_unhandled_handler(user_handler:function<Exception;any|void>)->function|undefined

variable_struct_exists<T:struct>(struct:T,name:string)->bool
variable_struct_get<T:struct>(struct:T,name:string)->any
variable_struct_set<T:struct>(struct:T,name:string,val:any)->void
variable_struct_get_names<T:struct>(struct:T)->string[]
variable_struct_names_count<T:struct>(struct:T)->int
variable_struct_remove<T:struct>(struct:T,name:string)->void
variable_get_hash(name:string)->int
variable_clone<T>(variable:T,?depth:int)->T
struct_exists<T:struct>(struct:T,name:string)->bool
struct_exists_from_hash<T:struct>(struct:T,hash:int)->bool
struct_get<T:struct>(struct:T,name:string)->any|undefined
struct_set<T:struct>(struct:T,name:string,val:any)->void
struct_get_names<T:struct>(struct:T)->string[]
struct_names_count<T:struct>(struct:T)->int
struct_remove<T:struct>(struct:T,name:string)->void
struct_remove_from_hash<T:struct>(struct:T,hash:int)->void 
struct_foreach<T:struct>(struct:T,predicate:function<member_name:string; value:any>)->void
struct_get_from_hash<T:struct>(struct:T,hash:int)->any
struct_set_from_hash<T:struct>(struct:T,hash:int,val:any)->void
array_length<T>(variable:T[])->int
array_length_1d<T>(variable:T[])&->int
array_length_2d<T>(variable:T[], index:int)&->int
array_height_2d<T>(variable:T[])&->int
array_resize<T>(variable:T[],newsize:int)->void
array_push<T>(array:T[],...values:T)->void
array_pop<T>(array:T[])->T
array_shift<T>(array:T[])->T
array_insert<T>(array:T[],index:int,...values:T)->void
array_delete<T>(array:T[],index:int,number:int)->void
array_sort<T>(array:T[],sortType_or_function:bool|function<T;T;int>)->void
array_shuffle<T>(array:T[],?offset:int,?length:int)->T
array_shuffle_ext<T>(array:T[],?offset:int,?length:int)->void
array_get_index<T>(array:T[],value:T,?offset:int,?length:int)->int
array_contains<T>(array:T[],value:T,?offset:int,?length:int)->bool
array_contains_ext<T>(array:T[],values:T[],?matchAll:bool,?offset:int,?length:int)->bool
//
array_first<T>(array:T[])->T
array_last<T>(array:T[])->T
array_create_ext<T>(size:int,generator:function<index:int; T>)->T[]
array_find_index<T>(array:T[], predicate:function<value:T; index:int; bool>, ?offset:int, ?length:int)->int
array_any<T>(array:T[], predicate:function<value:T; index:int; bool>, ?offset:int, ?length:int)->bool
array_all<T>(array:T[], predicate:function<value:T; index:int; bool>, ?offset:int, ?length:int)->bool
array_foreach<T>(array:T[], predicate:function<value:T; index:int; bool>, ?offset:int, ?length:int)->void
array_reduce<T;R>(array:T[], predicate:function<previous:R, current:T, index:int, R>, ?init_value:R, ?offset:int, ?length:int)->R
array_filter<T>(array:T[], filter:function<value:T; index:int; bool>, ?offset:int, ?length:int)->T[]
array_filter_ext<T>(array:T[], filter:function<value:T; index:int; bool>, ?offset:int, ?length:int)->int
array_map<T;R>(array:T[], predicate:function<value:T; index:int; R>, ?offset:int, ?length:int)->R[]
array_map_ext<T>(array:T[], predicate:function<value:T; index:int; T>, ?offset:int, ?length:int)->int
array_copy_while<T>(array:T[], predicate:function<value:T; index:int; bool>, ?offset:int, ?length:int)->T[]

array_unique<T>(array:T[], ?offset:int, ?length:int)->T[]
array_unique_ext<T>(array:T[], ?offset:int, ?length:int)->int
array_reverse<T>(array:T[], ?offset:int, ?length:int)->T[]
array_reverse_ext<T>(array:T[], ?offset:int, ?length:int)->int

array_concat<T>(...arrays:T[])->T[]
array_union<T>(...arrays:T[])->T[]
array_intersection<T>(...arrays:T[])->T[]

weak_ref_create<T:struct>(thing_to_track:T)->weak_reference
weak_ref_alive(weak_ref:weak_reference)->bool
weak_ref_any_alive(array:weak_reference[],?index:int,?length:int)->bool

#endregion

#region 2.3

handle_parse(val_string:string)->any|undefined    /// TODO: Handle type?

method<T:function>(context:method_auto_self<instance|struct|undefined>,func:method_auto_func<T>)->T
method_get_index<T:function>(method:T)->T
method_get_self<T:function>(method:T)->instance|struct|undefined

string_pos_ext(substr:string,str:string,startpos:int)->int
string_last_pos(substr:string,str:string)->int
string_last_pos_ext(substr:string,str:string,startpos:int)->int

string(val_or_template, ...values)->string
string_ext(format:string, arg_array:array)->string
string_trim_start(str:string, ?substrs:string[])->string
string_trim_end(str:string, ?substrs:string[])->string
string_trim(str:string, ?substrs:string[])->string
string_starts_with(str:string,substr:string)->bool
string_ends_with(str:string,substr:string)->bool
string_split(str:string, delim:string, ?remove_empty:bool, ?max_splits:int)->string[]
string_split_ext(str:string, delim_array:string[], ?remove_empty:bool, ?max_splits:int)->string[]
string_join(delim:string, ...values)->string
string_join_ext(delim:string, val_array:array, ?offset:int, ?length:int)->string
string_concat(...values)->string
string_concat_ext(val_array:array, ?offset:int, ?length:int)->string
string_foreach(str:string,func:function<char:string; pos:int; void>, ?pos:int, ?length:int)->void

#endregion

//////////////
// Chapter 403
//////////////

#region 3.1

place_empty<T:object|instance|layer_tilemap|array>(x:number,y:number,obj:T)->bool
place_meeting<T:object|instance|layer_tilemap|array>(x:number,y:number,obj:T)->bool
move_and_collide<T:object|instance|layer_tilemap|array>(dx:number,dy:number,obj:T,?num_iterations:int,?xoff:number,?yoff:number,?max_x_move:number,?max_y_move:number)->T[]

#endregion

#region 3.8

game_end(?return_code:int)->void
game_change(working_directory:string,launch_parameters:string)->void

scheduler_resolution_set(milliseconds:int)->void
scheduler_resolution_get()->int

#endregion

#region 3.9

// long-gone variables:
show_score&
show_lives&
show_health&
caption_score&
caption_lives&
caption_health&

#endregion

#region 3.10

event_perform_async(type:event_type,ds_map:ds_map)->void

ev_pre_create#:event_type
ev_draw_normal#:event_number
ev_trigger#:event_type
ev_audio_playback_ended#:event_type
ev_async_web_image_load#:event_type
ev_async_web#:event_type
ev_async_dialog#:event_type
ev_async_web_iap#:event_type
ev_async_web_cloud#:event_type
ev_async_web_networking#:event_type
ev_async_web_steam#:event_type
ev_async_social#:event_type
ev_async_push_notification#:event_type
ev_async_audio_recording#:event_type
ev_async_audio_playback#:event_type
ev_async_audio_playback_ended#:event_type
ev_async_system_event#:event_type

#endregion

#region 3.11

show_debug_message(val_or_format:any, ...values:any)->void
show_debug_message_ext(format:string, values_arr:array)->void
show_debug_overlay(enable:bool,?minimised:bool,?scale:number,?alpha:number)->void
is_debug_overlay_open()->bool
is_mouse_over_debug_overlay()->bool
is_keyboard_used_debug_overlay()->bool
show_debug_log(enable:bool)->void
debug_event(string:string,?silent:bool)->struct // TODO ResourceCounts and DumpMemory structs
debug_get_callstack(?maxDepth:int)->string[]

dbg_view(name:string,visible:bool,?x:number,?y:number,?width:number,?height:number)->debug_view
dbg_section(name:string,?open:bool)->debug_section
dbg_view_delete(view:debug_view)->void
dbg_view_exists(view:debug_view)->void
dbg_section_delete(section:debug_section)->bool
dbg_section_exists(section:debug_section)->bool
dbg_slider<T:number>(ref_or_array:debug_reference<T>|debug_reference<T>[],?minimum:number,?maximum:number,?label:string,?step:number)->void
dbg_slider_int<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],?minimum:int,?maximum:int,?label:string,?step:int)->void
dbg_drop_down<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],specifier:string|string[],?label:string)->void
dbg_watch<T:any>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)->void
dbg_text<T:string>(ref_or_array:T|debug_reference<T>|T[]|debug_reference<T>[])->void
dbg_text_separator<T:string>(ref_or_array:T|debug_reference<T>|T[]|debug_reference<T>[],?align:horizontal_alignment)->void
dbg_sprite<T:sprite>(ref_or_array:debug_reference<T>|debug_reference<T>[],index_ref_or_array:debug_reference<int>|debug_reference<int>[],?label:string,?width:number,?height:number)->void
dbg_text_input<T:string|int|number>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string,?type:string)->void
dbg_checkbox<T:bool>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)->void
dbg_colour<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)£->void
dbg_color<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)$->void
dbg_button<T:function>(label:string,callback_ref:T|debug_reference<T>,?width:number,?height:number)->void
dbg_sprite_button<T:function,R:sprite>(callback_ref:T|debug_reference<T>,sprite_ref_or_array:debug_reference<R>|debug_reference<R>[],index_ref_or_array:debug_reference<int>|debug_reference<int>[],?width:number,?height:number,?xoffset:number,?yoffset:number,?widthSprite:number,?heightSprite:number)->void
dbg_same_line()->void
dbg_add_font_glyphs(filename_ttf:string,?size:number,?font_range:int)->void
ref_create<T>(context:instance|struct|debug_reference<instance>|debug_reference<struct>,name:string|debug_reference<string>,?index:int)->debug_reference<T>

#endregion

//////////////
// Chapter 404
//////////////

#region 4.2

mb_side1#:mouse_button
mb_side2#:mouse_button

#endregion

//////////////
// Chapter 405
//////////////

#region 5.1

bboxkind_spine#:bbox_kind

// exception structure entries
[+message*@]??Exception
message?:string
longMessage?:string
script?:script
stacktrace?:Array<string>

// Sequence-related built-ins
in_sequence@:bool
sequence_instance@:sequence_instance
drawn_by_sequence@:bool

#endregion

#region 5.4

draw_clear_depth(depth:number)->void
draw_clear_stencil(stencil:int)->void
draw_clear_ext(?color:int,alpha:number,depth:number,stencil:int)->void

#endregion

#region 5.6

font_get_info(font:font)->font_info
font_cache_glyph(font:font,glyphIndex:int)->font_glyph_cache

bm_min#:blendmode
bm_reverse_subtract#:blendmode
bm_eq_add#:blendmode_equation
bm_eq_max#:blendmode_equation
bm_eq_subtract#:blendmode_equation
bm_eq_min#:blendmode_equation
bm_eq_reverse_subtract#:blendmode_equation

audio_falloff_inverse_distance_scaled#:audio_falloff_model
audio_falloff_exponent_distance_scaled#:audio_falloff_model

#endregion

#region section 5.7_1

surface_create(w:int,h:int,?format:surface_format)->surface
surface_get_texture_depth(id:surface)->texture
surface_get_format(id:surface)->surface_format
surface_set_target(id:surface,?depth_id:surface)->bool
surface_get_target_depth()->surface
surface_has_depth(id:surface)->bool
surface_format_is_supported(format:surface_format)->bool

surface_rgba8unorm#:surface_format
surface_r16float#:surface_format
surface_r32float#:surface_format
surface_rgba4unorm#:surface_format
surface_r8unorm#:surface_format
surface_rg8unorm#:surface_format
surface_rgba16float#:surface_format
surface_rgba32float#:surface_format

video_open(path:string)->void
video_close()->void
video_set_volume(vol:number)->void
video_draw()->tuple<status:int,surface_rgba_or_yuv:surface,surface_chroma:surface>
video_pause()->void
video_resume()->void
video_enable_loop(enable:bool)->void
video_seek_to(milliseconds:int)->void
video_get_duration()->int
video_get_position()->int
video_get_status()->video_status
video_get_format()->video_format
video_is_looping()->bool
video_get_volume()->number

video_format_rgba#:video_format
video_format_yuv#:video_format
video_status_closed#:video_status
video_status_preparing#:video_status
video_status_playing#:video_status
video_status_paused#:video_status

#endregion

#region 5.8

display_get_frequency()->int

#endregion

#region 5.9

window_set_showborder(show:bool)->void
window_get_showborder()->bool
window_enable_borderless_fullscreen(enable:bool)->void
window_get_borderless_fullscreen()->bool
window_minimise()£->void
window_minimize()$->void
window_restore()->void
window_mouse_set_locked(enable:bool)->void
window_mouse_get_locked()->bool
window_mouse_get_delta_x()->number
window_mouse_get_delta_y()->number

#endregion

//////////////
// Chapter 406
//////////////

#region 6.3

audio_system()&->void
audio_play_sound(soundid:sound,priority:int,loops:bool,?gain:real,?offset:real,?pitch:real,?listener_mask:int)->sound_instance
audio_play_sound_on(emitterid:audio_emitter,soundid:sound,loops:bool,priority:int,?gain:real,?offset:real,?pitch:real,?listener_mask:int)->sound_instance
audio_play_sound_at(soundid:sound,x:number,y:number,z:number, falloff_ref_dist:number,falloff_max_dist:number,falloff_factor:number,loops:bool, priority:int,?gain:real,?offset:real,?pitch:real,?listener_mask:int)->sound_instance
audio_play_sound_ext(params:any_fields_of<audio_play_sound_ext_t>)->sound_instance
audio_system_is_initialised()->bool

audio_sound_get_asset(voiceIndex:sound_instance)->sound|undefined
audio_sound_loop(voiceIndex:sound_instance, loopState:bool)->void
audio_sound_get_loop(voiceIndex:sound_instance)->bool
audio_sound_loop_start(index:sound|sound_instance, time:number)->void
audio_sound_get_loop_start(index:sound|sound_instance)->number
audio_sound_loop_end(index:sound|sound_instance, time:number)->void
audio_sound_get_loop_end(index:sound|sound_instance)->number

audio_sync_group_is_paused(sync_group_id:sound_sync_group)->bool

audio_throw_on_error(enable:bool)->void

audio_group_get_gain(groupId:audio_group)->number
audio_group_get_assets(groupId:audio_group)->sound[]
audio_sound_get_audio_group(index:sound|sound_instance)->audio_group

#endregion

//////////////
// Chapter 407
//////////////

//////////////
// Chapter 408
//////////////

#region 8.1

sprite_get_info(ind:sprite)->sprite_info|undefined
sprite_get_nineslice(ind:sprite)->nineslice
sprite_set_nineslice(ind:sprite,nineslice:nineslice)->void
sprite_nineslice_create()->nineslice

texturegroup_get_names()->string[]

texturegroup_load(groupname:string,?prefetch=true)->int
texturegroup_unload(groupname:string)->void
texturegroup_get_status(groupname:string)->texture_group_status
texturegroup_set_mode(explicit:bool,debug:bool,default_sprite:sprite)->void

#endregion

#region 8.9

room_get_info(room:room,?views:bool,?instances:bool,?layers:bool,?layer_elements:bool,?tilemap_data:bool)->room_info

#endregion

//////////////
// Chapter 409
//////////////

#region 9.1

sprite_add_ext(name:string,imgnumb:number,xorig:number,yorig:number,prefetch:bool)->sprite

sprite_add_ext_error_unknown#:sprite_add_ext_error
sprite_add_ext_error_cancelled#:sprite_add_ext_error
sprite_add_ext_error_spritenotfound#:sprite_add_ext_error
sprite_add_ext_error_loadfailed#:sprite_add_ext_error
sprite_add_ext_error_decompressfailed#:sprite_add_ext_error
sprite_add_ext_error_setupfailed#:sprite_add_ext_error

#endregion

#region 9.4
font_enable_sdf(ind:font,enable:bool)->void
font_get_sdf_enabled(ind:font)->bool
font_sdf_spread(ind:font,spread:number)->void
font_get_sdf_spread(ind:font)->number

font_enable_effects(ind:font, enable:bool, ?params:font_effect_params|struct)->void

#endregion

#region 9.6

script_execute_ext(ind:script,?args:any[],?offset:int=0,?num_args:int=args_length-offset)->any
method_call<T:function>(method:T,?args:any[],?offset:int=0,?num_args:int=args_length-offset)->any

#endregion

#region 9.9

asset_get_ids(asset_type:asset_type)->array

asset_sequence#:asset_type
asset_animationcurve#:asset_type
asset_particlesystem#:asset_type

#endregion

//////////////
// Chapter 410
//////////////

#region 10.1

cache_directory*:string

#endregion

//////////////
// Chapter 411
//////////////

#region 11.0

ds_set_precision(prec:number)->void

#endregion

#region 11.3 - list

ds_list_destroy<T>(list:ds_list<T>)->void
ds_list_clear<T>(list:ds_list<T>)->void
ds_list_copy<T>(list:ds_list<T>, source:ds_list<T>)->void
ds_list_add<T>(list:ds_list<T>, ...values:T)->void
ds_list_insert<T>(list:ds_list<T>, pos:int, value:T)->void
ds_list_replace<T>(list:ds_list<T>, pos:int, value:T)->void
ds_list_delete<T>(list:ds_list<T>, pos:int)->void
ds_list_is_map<T>(list:ds_list<T>, pos:int)->bool
ds_list_is_list<T>(list:ds_list<T>, pos:int)->bool
ds_list_mark_as_list<T>(list:ds_list<T>,pos:int)->void
ds_list_mark_as_map<T>(list:ds_list<T>,pos:int)->void
ds_list_sort<T>(list:ds_list<T>,ascending:bool)->void
ds_list_shuffle<T>(list:ds_list<T>)->void
ds_list_read<T>(list:ds_list<T>, str:string, ?legacy:bool)->void
ds_list_set<T>(list:ds_list<T>,pos:int,value:T)->void

#endregion

#region 11.4 - map

ds_map_create()->ds_map
ds_map_destroy<K;V>(map:ds_map<K;V>)->void
ds_map_clear<K;V>(map:ds_map<K;V>)->void
ds_map_copy<K;V>(map:ds_map<K;V>, source:ds_map<K;V>)->void
ds_map_add_list<K;V>(map:ds_map<K;V>,key:K,value:V)->void
ds_map_add_map<K;V>(map:ds_map<K;V>,key:K,value:V)->void
ds_map_replace_map<K;V>(map:ds_map<K;V>,key:K,value:V)->void
ds_map_replace_list<K;V>(map:ds_map<K;V>,key:K,value:V)->void
ds_map_delete<K;V>(map:ds_map<K;V>,key:K)->void
ds_map_keys_to_array<K;V>(map:ds_map<K;V>, ?K[])->K[]
ds_map_values_to_array<K;V>(map:ds_map<K;V>, ?V[])->V[]
ds_map_is_map<K;V>(map:ds_map<K;V>,key:K)->bool
ds_map_is_list<K;V>(map:ds_map<K;V>,key:K)->bool
ds_map_read<K;V>(map:ds_map<K;V>, str:string, ?legacy:bool)->void
ds_map_secure_save<K;V>(map:ds_map<K;V>, filename:string)->void
ds_map_set<K;V>(map:ds_map<K;V>,key:K,value:V)->void

#endregion

#region 11.6

ds_grid_create(w:int,h:int)->ds_grid
ds_grid_destroy<T>(grid:ds_grid<T>)->void
ds_grid_copy<T>(grid:ds_grid<T>, source:ds_grid<T>)->void
ds_grid_resize<T>(grid:ds_grid<T>, w:int, h:int)->void
ds_grid_clear<T>(grid:ds_grid<T>, val:T)->void
ds_grid_add<T>(grid:ds_grid<T>,x:int,y:int,val:T)->void
ds_grid_multiply<T>(grid:ds_grid<T>,x:int,y:int,val:T)->void
ds_grid_set_region<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)->void
ds_grid_add_region<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)->void
ds_grid_multiply_region<T>(grid:ds_grid<T>,x1:int,y1:int,x2:int,y2:int,val:T)->void
ds_grid_set_disk<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)->void
ds_grid_add_disk<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)->void
ds_grid_multiply_disk<T>(grid:ds_grid<T>,xm:number,ym:number,r:number,val:T)->void
ds_grid_set_grid_region<T>(grid:ds_grid<T>,source,x1:int,y1:int,x2:int,y2:int,xpos,ypos)->void
ds_grid_add_grid_region<T>(grid:ds_grid<T>,source,x1:int,y1:int,x2:int,y2:int,xpos,ypos)->void
ds_grid_multiply_grid_region<T>(grid:ds_grid<T>,source,x1:int,y1:int,x2:int,y2:int,xpos,ypos)->void
ds_grid_shuffle<T>(grid:ds_grid<T>)->void
ds_grid_read<T>(grid:ds_grid<T>, str:string, ?legacy:bool)->void
ds_grid_sort<T>(grid:ds_grid<T>, column:int, ascending:bool)->void
ds_grid_set<T>(grid:ds_grid<T>, x:int, y:int, value:T)->void
ds_grid_get<T>(grid:ds_grid<T>, x:int, y:int)->void
ds_grid_to_mp_grid<T:number>(ds_grid:ds_grid<T>,mp_grid:mp_grid,?func:function<value:T;x:int;y:int,void>)->void

#endregion

//////////////
// Chapter 412
//////////////

#region 12.1a

effect_create_layer(layer_id_or_name:layer|string,kind:effect_kind,x:number,y:number,size:number,col:int)->void
effect_create_depth(depth:int,kind:effect_kind,x:number,y:number,size:number,col:int)->void
effect_clear()->void

#endregion

#region 12

part_type_subimage(ind:particle,subimg:int)->void
part_type_size_x(ind:particle,size_min_x:number,size_max_x:number,size_incr_x:number,size_wiggle_y:number)->void
part_type_size_y(ind:particle,size_min_y:number,size_max_y:number,size_incr_y:number,size_wiggle_y:number)->void

#endregion

#region 12.2

particle_get_info(particles:particle_asset)->particle_system_info
particle_exists(particles:particle_asset)->bool

part_system_create(?particles:particle_asset)->particle_system
part_system_color(ind:particle_system,color:int,alpha:number)$->void
part_system_colour(ind:particle_system,colour:int,alpha:number)£->void
part_system_angle(ind:particle_system,angle:int)->void
part_system_global_space(ind:particle_system,enable:bool)->void
part_system_get_info(ind:particle_system)->particle_system_info

part_particles_burst(ind:particle_system,x:number,y:number,particles:particle_asset)->void

#endregion

#region 12.3

part_emitter_enable(ps:particle_system,ind:particle_emitter,enable:bool)->void
part_emitter_delay(ps:particle_system,ind:particle_emitter,delay_min:number,delay_max:number,delay_unit:time_source_units)->void
part_emitter_interval(ps:particle_system,ind:particle_emitter,interval_min:number,interval_max:number,inerval_unit:time_source_units)->void
part_emitter_relative(ps:particle_system,ind:particle_emitter,enable:bool)->void
ps_mode_stream#:particle_mode
ps_mode_burst#:particle_mode

#endregion

//////////////
// Chapter 414
//////////////

//////////////
// Chapter 415
//////////////

matrix_transform_vertex(matrix:number[], x:number, y:number, z:number, ?w:number)->number[]
matrix_inverse(matrix:number[])->number[]

os_ps4#:os_type
os_ps5#:os_type
os_xboxseriesxs#:os_type
os_gdk#:os_type
os_operagx#:os_type
os_gxgames#:os_type

os_request_permission(...permissions:string)->void
os_set_orientation_lock(landscape_enable:bool,portrait_enable:bool)->void
event_data*:ds_map<string,any>

tm_systemtiming#:display_timing_method

draw_enable_svg_aa(enable:bool)!->void
draw_set_svg_aa_level(aa_level:number)!->void
draw_get_svg_aa_level()!->number

stencilop_keep#:gpu_stencilop
stencilop_zero#:gpu_stencilop
stencilop_replace#:gpu_stencilop
stencilop_incr_wrap#:gpu_stencilop
stencilop_decr_wrap#:gpu_stencilop
stencilop_invert#:gpu_stencilop
stencilop_incr#:gpu_stencilop
stencilop_decr#:gpu_stencilop

gpu_set_stencil_depth_fail(stencil_op:gpu_stencilop)->void
gpu_set_stencil_enable(enable:bool)->void
gpu_set_stencil_fail(stencil_op:gpu_stencilop)->void
gpu_set_stencil_func(cmp_func:gpu_cmpfunc)->void
gpu_set_stencil_pass(stencil_op:gpu_stencilop)->void
gpu_set_stencil_read_mask(mask:int)->void
gpu_set_stencil_ref(ref:int)->void
gpu_set_stencil_write_mask(mask:int)->void
gpu_set_sprite_cull(enable:bool)->void
gpu_set_depth(depth:int)->void
gpu_set_blendequation(equation:blendmode_equation)->void
gpu_set_blendequation_sepalpha(equation:blendmode_equation, equation_alpha:blendmode_equation)->void

gpu_set_tex_mip_enable(setting:texture_mip_state)->void
gpu_set_tex_mip_enable_ext(sampler_id:shader_sampler,setting:texture_mip_state)->void

gpu_get_stencil_enable()->bool
gpu_get_stencil_func()->gpu_cmpfunc
gpu_get_stencil_ref()->int
gpu_get_stencil_read_mask()->int
gpu_get_stencil_write_mask()->int
gpu_get_stencil_fail()->gpu_stencilop
gpu_get_stencil_depth_fail()->gpu_stencilop
gpu_get_stencil_pass()->gpu_stencilop
gpu_get_sprite_cull()->bool
gpu_get_depth()->int
gpu_get_blendequation()->blendmode_equation
gpu_get_blendequation_sepalpha()->tuple<equation:blendmode_equation,equation_alpha:blendmode_equation>

gpu_get_scissor()->{x:number,y:number,w:number,h:number}
gpu_set_scissor(x_or_struct:number|struct, ?y:number, ?w:number, ?h:number)->void

gamepad_enumerate()->void

http_get_connect_timeout()->int
http_set_connect_timeout(connect_timeout_ms:int)->void
json_encode(ds_map:ds_map<string;any>, ?prettify:bool)->string
json_stringify<T:struct|array|number|string|undefined>(val:T,?prettify:bool,?filter_func:function<key:string|int; value:any; any>)->string
json_parse(json:string, ?filter_func:function<key:string|int; value:any; any>, ?inhibit_string_convert:bool = false)->any
zip_unzip_async(zip_file:string, target_directory:string)->int
zip_create()->zip_object
zip_add_file(zip_object:zip_object, dest:string, src:string)->int
zip_save(zip_object:zip_object, path:string)->int

os_is_network_connected(?attempt_connection:bool|network_connect_type)->bool

physics_raycast<T:object|instance>(x_start:number, y_start:number, x_end:number, y_end:number, ids:T|T[], ?all_hits:bool = false, ?max_fraction:number)->physics_hitpoint[]?

network_send_raw(socket:network_socket, bufferid:buffer, size:int, ?option:network_send_option)->int

network_socket_ws#:network_type
network_socket_wss#:network_type
network_config_avoid_time_wait#:network_config
network_type_up#:network_async_id
network_type_up_failed#:network_async_id
network_type_down#:network_async_id
network_send_binary#:network_send_option
network_send_text#:network_send_option

network_config_websocket_protocol#:network_config
network_config_enable_multicast#:network_config
network_config_disable_multicast#:network_config

network_connect_none#:network_connect_type
network_connect_blocking#:network_connect_type
network_connect_nonblocking#:network_connect_type
network_connect_active#:network_connect_type
network_connect_passive#:network_connect_type

buffer_write(buffer:buffer, type:buffer_type, value:buffer_auto_type)->buffer_write_error
buffer_get_surface(buffer:buffer, source_surface:surface, offset:int)->void
buffer_get_surface_depth(buffer:buffer, source_surface:surface, offset:int)->bool
buffer_set_surface(buffer:buffer, dest_surface:surface, offset:int)->void
buffer_set_surface_depth(buffer:buffer, dest_surface:surface, offset:int)->bool
buffer_set_used_size(buffer:buffer,size:int)->void
buffer_copy_stride(src_buffer:buffer, src_offset:int, src_size:int, src_stride:int, src_count:int, dest_buffer:buffer, dest_offset:int, dest_stride:int)->void

buffer_surface_copy&:any
buffer_error_general#:buffer_write_error
buffer_error_out_of_space#:buffer_write_error
buffer_error_invalid_type#:buffer_write_error

gp_axis_acceleration_x#:gamepad_button
gp_axis_acceleration_y#:gamepad_button
gp_axis_acceleration_z#:gamepad_button

gp_axis_angular_velocity_x#:gamepad_button
gp_axis_angular_velocity_y#:gamepad_button
gp_axis_angular_velocity_z#:gamepad_button

gp_axis_orientation_x#:gamepad_button
gp_axis_orientation_y#:gamepad_button
gp_axis_orientation_z#:gamepad_button
gp_axis_orientation_w#:gamepad_button

gp_home#:gamepad_button
gp_extra1#:gamepad_button
gp_extra2#:gamepad_button
gp_extra3#:gamepad_button
gp_extra4#:gamepad_button
gp_paddler#:gamepad_button
gp_paddlel#:gamepad_button
gp_paddlerb#:gamepad_button
gp_paddlelb#:gamepad_button
gp_touchpadbutton#:gamepad_button
gp_extra5#:gamepad_button
gp_extra6#:gamepad_button

shader_set_uniform_f_buffer(uniform_id:shader_uniform,buffer:buffer,offset:int,count:int)->void

vertex_format_get_info(format_id:vertex_format)->vertex_format_info

vertex_submit_ext(vbuff:vertex_buffer,primtype:primitive_type,texture:texture,offset:int,num:int)->void
vertex_update_buffer_from_buffer(dest_vbuff:vertex_buffer,dest_offset:int,src_buffer:buffer,?src_offset:int,?src_size:int)->void
vertex_update_buffer_from_vertex(dest_vbuff:vertex_buffer,dest_vert:int,src_vbuff:vertex_buffer,?src_vert:int,?src_vert_num:int)->void

skeleton_animation_set(anim_name:string, ?loop:bool)!->void
skeleton_animation_set_ext(anim_name:string, track:int, ?loop:bool)!->void
skeleton_animation_clear(track:int,?reset:bool,duration:number)!->void
skeleton_skin_set<T:string|skeleton_skin>(skin_name:T)!->void
skeleton_skin_create(skin_name:string, base_skins:string[])!->skeleton_skin
skeleton_attachment_set(slot:string, attachment:string|sprite)!->string
skeleton_attachment_exists(name:string)!->bool
skeleton_attachment_replace(name:string, sprite:sprite, ind:int, xorigin:number, yorigin:number, xscale:number, yscale:number, rot:number)!->int
skeleton_attachment_replace_colour(name:string, sprite:sprite, ind:int, xorigin:number, yorigin:number, xscale:number, yscale:number, rot:number, colour:int, alpha:number)!£->int
skeleton_attachment_replace_color(name:string, sprite:sprite, ind:int, xorigin:number, yorigin:number, xscale:number, yscale:number, rot:number, color:int, alpha:number)!$->int
skeleton_attachment_destroy(name:string)!->void

skeleton_animation_get_position(track:int)!->number
skeleton_animation_set_position(track:int,position:number)!->void
skeleton_animation_is_looping(track:int)!->bool
skeleton_animation_is_finished(track:int)!->bool

skeleton_slot_data_instance(list:ds_list<ds_map<string;any>>)!->void

layer_get_all()->layer[]

layerelementtype_text#:layer_element_type

tileset_get_info(tileset_id)->tileset_info|undefined

camera_copy_transforms(dest_camera:camera,src_camera:camera)->void

camera_set_view_target<T:instance|object>(camera:camera,object:T)->void
camera_get_view_target<T:instance|object>(camera:camera)->T|any

keyboard_virtual_show(virtual_keyboard_type:virtual_keyboard_type, virtual_return_key_type:virtual_keyboard_return_key, auto_capitalization_type:virtual_keyboard_autocapitalization, predictive_text_enabled:bool)->void

nineslice_left#:nineslice_tile_index
nineslice_top#:nineslice_tile_index
nineslice_right#:nineslice_tile_index
nineslice_bottom#:nineslice_tile_index
nineslice_centre#:nineslice_tile_index
nineslice_center#:nineslice_tile_index

nineslice_stretch#:nineslice_tile_mode
nineslice_repeat#:nineslice_tile_mode
nineslice_mirror#:nineslice_tile_mode
nineslice_blank#:nineslice_tile_mode
nineslice_hide#:nineslice_tile_mode

texturegroup_status_unloaded#:texture_group_status
texturegroup_status_loading#:texture_group_status
texturegroup_status_loaded#:texture_group_status
texturegroup_status_fetched#:texture_group_status

//tags
tag_get_asset_ids(tags:string|string[],asset_type:asset_type)->asset[]
tag_get_assets(tags:string|string[])->string[]
asset_get_tags(asset_name_or_id:string|asset,?asset_type:asset_type)->string[]
asset_add_tags(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_remove_tags(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_has_tags(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_has_any_tag(asset_name_or_id:string|asset,tags:string|string[],?asset_type:asset_type)->bool
asset_clear_tags(asset_name_or_id:string|asset,?asset_type:asset_type)->bool

//extension options
extension_exists(ext_name:string)->bool
extension_get_version(ext_name:string)->string
extension_get_option_count(ext_name:string)->int
extension_get_option_names(ext_name:string)->string[]
extension_get_option_value(ext_name:string, option_name:string)->any
extension_get_options(ext_name:string)->struct

//sequences
layer_sequence_get_instance(sequence_element_id:layer_sequence)->sequence_instance
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
layer_sequence_get_sequence(sequence_element_id:layer_sequence)->sequence_object
layer_sequence_is_paused(sequence_element_id:layer_sequence)->bool
layer_sequence_is_finished(sequence_element_id:layer_sequence)->bool
layer_sequence_get_speedscale(sequence_element_id:layer_sequence)->number

layer_sequence_get_length(sequence_element_id:layer_sequence)->int

// text items
layer_text_get_id(layer_id:layer|string,text_element_name:string)->layer_text
layer_text_exists(layer_id:layer|string,text_element_id:layer_text)->bool

layer_text_create(layer_id:layer|string,x:number,y:number,font:font,text:string)->layer_text
layer_text_destroy(text_element_id:layer_text)->void
layer_text_x(text_element_id:layer_text,x:number)->void
layer_text_y(text_element_id:layer_text,y:number)->void
layer_text_angle(text_element_id:layer_text,angle:number)->void
layer_text_xscale(text_element_id:layer_text,scale:number)->void
layer_text_yscale(text_element_id:layer_text,scale:number)->void
layer_text_blend(text_element_id:layer_text,col:int)->void
layer_text_alpha(text_element_id:layer_text,alpha:number)->void
layer_text_font(text_element_id:layer_text,font:font)->void
layer_text_xorigin(text_element_id:layer_text,xorigin:number)->void
layer_text_yorigin(text_element_id:layer_text,yorigin:number)->void
layer_text_text(text_element_id:layer_text,text:string)->void
layer_text_halign(text_element_id:layer_text,alignment:text_horizontal_alignment)->void
layer_text_valign(text_element_id:layer_text,alignment:text_vertical_alignment)->void
layer_text_charspacing(text_element_id:layer_text,charspacing:number)->void
layer_text_linespacing(text_element_id:layer_text,linespacing:number)->void
layer_text_framew(text_element_id:layer_text,width:number)->void
layer_text_frameh(text_element_id:layer_text,height:number)->void
layer_text_wrap(text_element_id:layer_text,wrap:bool)->void

layer_text_get_x(text_element_id:layer_text)->number
layer_text_get_y(text_element_id:layer_text)->number
layer_text_get_xscale(text_element_id:layer_text)->number
layer_text_get_yscale(text_element_id:layer_text)->number
layer_text_get_angle(text_element_id:layer_text)->number
layer_text_get_blend(text_element_id:layer_text)->int
layer_text_get_alpha(text_element_id:layer_text)->number
layer_text_get_font(text_element_id:layer_text)->font
layer_text_get_xorigin(text_element_id:layer_text)->number
layer_text_get_yorigin(text_element_id:layer_text)->number
layer_text_get_text(text_element_id:layer_text)->string
layer_text_get_halign(text_element_id:layer_text)->text_horizontal_alignment
layer_text_get_valign(text_element_id:layer_text)->text_vertical_alignment
layer_text_get_charspacing(text_element_id:layer_text)->number
layer_text_get_linespacing(text_element_id:layer_text)->number
layer_text_get_framew(text_element_id:layer_text)->number
layer_text_get_frameh(text_element_id:layer_text)->number
layer_text_get_wrap(text_element_id:layer_text)->bool

// Text element alignment
textalign_left#:text_horizontal_alignment
textalign_center#:text_horizontal_alignment
textalign_right#:text_horizontal_alignment
textalign_justify#:text_horizontal_alignment
textalign_top#:text_vertical_alignment
textalign_middle#:text_vertical_alignment
textalign_bottom#:text_vertical_alignment

// Animation Curves
animcurve_get(curve_id:animcurve)->animcurve_struct
animcurve_get_channel(curve_struct_or_id:animcurve_struct|animcurve,channel_name_or_index:string|int)->animcurve_channel
animcurve_get_channel_index(curve_struct_or_id:animcurve_struct|animcurve,channel_name:string)->int
animcurve_channel_evaluate(channel:animcurve_channel,posx:number)->number

// Sequence resource creation functions
sequence_create()->sequence_object
sequence_destroy(sequence_object_or_id:sequence_object|sequence)->void
sequence_exists(sequence_object_or_id:sequence_object|sequence)->bool
sequence_get(sequence_id:sequence)->sequence_object
sequence_keyframe_new(type:sequence_track_type)->sequence_keyframe
sequence_keyframedata_new<T:sequence_keyframe_data>(type:sequence_track_type)->T
sequence_track_new(type:sequence_track_type)->sequence_track

sequence_get_objects(sequence_object_or_id:sequence_object|sequence)->object[]
sequence_instance_override_object(sequence_instance_struct:sequence_instance,object_id:object,instance_or_object_id:instance|object)->void

// Animation curve resource creation functions
animcurve_create()->animcurve_struct
animcurve_destroy(curve_struct_or_id:animcurve_struct|animcurve)->void
animcurve_exists(curve_struct_or_id:animcurve_struct|animcurve)->bool
animcurve_channel_new()->animcurve_channel
animcurve_point_new()->animcurve_point

// Effects functions
fx_create(filter_or_effect_name:string)->fx_struct
fx_get_name(filter_or_effect:fx_struct)->string
fx_get_parameter_names(filter_or_effect:fx_struct)->string[]
fx_get_parameter<T:number|number[]|bool|texture>(filter_or_effect:fx_struct,parameter_name:string)->T
fx_get_parameters(filter_or_effect:fx_struct)->struct
fx_get_single_layer(filter_or_effect:fx_struct)->bool
fx_set_parameter<T:number|number[]|bool|texture>(filter_or_effect:fx_struct,parameter_name:string,...val:T)->void
fx_set_parameters(filter_or_effect:fx_struct,parameter_struct:struct)->void
fx_set_single_layer(filter_or_effect:fx_struct,enable:bool)->void

layer_set_fx(layer_name_or_id:layer|string,filter_or_effect:fx_struct)->void
layer_get_fx(layer_name_or_id:layer|string)->fx_struct
layer_clear_fx(layer_name_or_id:layer|string)->void
layer_enable_fx(layer_name_or_id:layer|string,enable:bool)->void
layer_fx_is_enabled(layer_name_or_id:layer|string)->bool


// SequenceInstance properties
??SequenceInstance
sequence?:sequence_object
headPosition?:int
headDirection?:sequence_direction
speedScale?:number
volume?:number
paused?:bool
finished?:bool
activeTracks?:Array<sequence_active_track>
elementID?:layer_sequence

// Sequence properties
??Sequence
name?:string
loopmode?:sequence_play_mode
playbackSpeed?:number
playbackSpeedType?:sprite_speed_type
length?:int
volume?:number
xorigin?:number
yorigin?:number
tracks?:Array<sequence_track>
messageEventKeyframes?:Array<sequence_keyframe>
momentKeyframes?:Array<sequence_keyframe>
event_create?:function
{}
event_destroy?:function
{}
event_clean_up?:function
{}
event_step?:function
{}
event_step_begin?:function
{}
event_step_end?:function
{}
event_async_system?:function
{}
event_broadcast_message?:function
{}

// Track properties
??Track
name?:string
type?:sequence_track_type
subType? // deprecated
traits? // deprecated
tracks?:Array<sequence_track>
interpolation?:sequence_interpolation
enabled?:bool
visible?:bool
linked? // deprecated
linkedTrack? // deprecated
keyframes?:Array<sequence_keyframe>

// Keyframe properties
??Keyframe
frame?:int
length?:int
stretch?:bool
disabled? // deprecated
channels?:Array<sequence_keyframe_data>

// Common key channel properties
??KeyChannel
channel?:int

// Graphic track key
??GraphicTrack
spriteIndex?:sprite

// Sequence track key
??SequenceTrack
sequence?:sequence_object

// Audio track key
??AudioTrack
soundIndex?:sound_instance
emitterIndex?:audio_emitter
playbackMode?:sequence_audio_mode

// Sprite frames track
??SpriteTrack
imageIndex?:int

// Bool track
??BoolTrack
value?:bool

// String track
??StringTrack
value?:string

// Colour track
??ColourTrack
colour?:int

??ColorTrack
color?:int

// Real track
??RealTrack
value?:number
curve?:animcurve_struct

// Instance track
??InstanceTrack
objectIndex?:object

// Text track
??TextTrack
text?:string
wrap?:bool
alignmentV?:text_vertical_alignment
alignmentH?:text_horizontal_alignment
fontIndex?:font
effectsEnabled?:bool
glowEnabled?:bool
outlineEnabled?:bool
dropShadowEnabled?:bool

// Message event
??MessageEvent
events?:Array<string>

// Moment key
??Moment
event?:function
{}

// AnimCurve properties
??AnimCurve
name?:string
graphType?:int
channels?:Array<animcurve_channel>

// AnimCurveChannel properties
??AnimCurveChannel
type?:animcurve_interpolation
iterations?:int
points?:Array<animcurve_point>

// AnimCurvePoint properties
??AnimCurvePoint
posx?:number
value?:number

// TrackEvalNode properties
??TrackEvalNode
activeTracks?:Array<sequence_track>
matrix?:Array<number>
posx?:number
posy?:number
rotation?:number
scalex?:number
scaley?:number
xorigin?:number
yorigin?:number
gain?:number
pitch?:number
falloffRef?:number
falloffMax?:number
falloffFactor?:number
width?:number
height?:number
imageindex?:int
imagespeed?:number
colormultiply?:tuple<a:number,r:number,g:number,b:number>
colourmultiply?:tuple<a:number,r:number,g:number,b:number>
coloradd?:tuple<a:number,r:number,g:number,b:number>
colouradd?:tuple<a:number,r:number,g:number,b:number>
spriteIndex?:sprite
emitterIndex?:audio_emitter
soundIndex?:sound_instance
instanceID?:instance
sequenceID?:sequence
sequence?:sequence_object
frameSizeX?:number
frameSizeY?:number
characterSpacing?:number
lineSpacing?:number
paragraphSpacing?:number
thickness?:number
coreColor?:tuple<a:number,r:number,g:number,b:number>
coreColour?:tuple<a:number,r:number,g:number,b:number>
glowStart?:number
glowEnd?:number
glowColor?:tuple<a:number,r:number,g:number,b:number>
glowColour?:tuple<a:number,r:number,g:number,b:number>
outlineDist?:number
outlineColor?:tuple<a:number,r:number,g:number,b:number>
outlineColour?:tuple<a:number,r:number,g:number,b:number>
shadowSoftness?:number
shadowOffsetX?:number
shadowOffsetY?:number
shadowColor?:tuple<a:number,r:number,g:number,b:number>
shadowColour?:tuple<a:number,r:number,g:number,b:number>
effectsEnabled?:bool
glowEnabled?:bool
outlineEnabled?:bool
dropShadowEnabled?:bool
track?:sequence_track
parent?:sequence_instance

// Sequence track types
seqtracktype_graphic#:sequence_track_type
seqtracktype_audio#:sequence_track_type
seqtracktype_real#:sequence_track_type
seqtracktype_color#:sequence_track_type
seqtracktype_colour#:sequence_track_type
seqtracktype_bool#:sequence_track_type
seqtracktype_string#:sequence_track_type
seqtracktype_sequence#:sequence_track_type
seqtracktype_clipmask#:sequence_track_type
seqtracktype_clipmask_mask#:sequence_track_type
seqtracktype_clipmask_subject#:sequence_track_type
seqtracktype_group#:sequence_track_type
seqtracktype_empty#:sequence_track_type
seqtracktype_spriteframes#:sequence_track_type
seqtracktype_instance#:sequence_track_type
seqtracktype_message#:sequence_track_type
seqtracktype_moment#:sequence_track_type
seqtracktype_text#:sequence_track_type
seqtracktype_particlesystem#:sequence_track_type
seqtracktype_audioeffect#:sequence_track_type

// Sequence playback mode constants
seqplay_oneshot#:sequence_play_mode
seqplay_loop#:sequence_play_mode
seqplay_pingpong#:sequence_play_mode

// Sequence playback direction constants
seqdir_right#:sequence_direction
seqdir_left#:sequence_direction

// Sequence real track interpolation modes
seqinterpolation_assign#:sequence_interpolation
seqinterpolation_lerp#:sequence_interpolation

// Sequence audio key play mode
seqaudiokey_loop#:sequence_audio_mode
seqaudiokey_oneshot#:sequence_audio_mode

// Text track alignment
seqtextkey_left#:text_horizontal_alignment
seqtextkey_center#:text_horizontal_alignment
seqtextkey_right#:text_horizontal_alignment
seqtextkey_justify#:text_horizontal_alignment
seqtextkey_top#:text_vertical_alignment
seqtextkey_middle#:text_vertical_alignment
seqtextkey_bottom#:text_vertical_alignment

// Anim curve channel type
animcurvetype_linear#:animcurve_interpolation
animcurvetype_catmullrom#:animcurve_interpolation
animcurvetype_bezier#:animcurve_interpolation

// Garbage collection functions
gc_collect()->void
gc_enable(enable:bool)->void
gc_is_enabled()->bool
gc_get_stats()->gc_stats
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

// weak reference functions
weak_ref_create<T:struct|instance>(thing_to_track:T)->weak_reference<T>

// weak reference structure
??WeakRef
ref?:struct|instance

time_source_global#:time_source
time_source_game#:time_source

time_source_create(parent:time_source, period:number, units:time_source_units, callback:function, ?args:array, ?reps:number, ?expiryType:time_source_expiry)->time_source
time_source_destroy(id:time_source, ?destroyTree:bool)->void
time_source_start(id:time_source)->void
time_source_stop(id:time_source)->void
time_source_pause(id:time_source)->void
time_source_resume(id:time_source)->void
time_source_reset(id:time_source)->void
time_source_reconfigure(id:time_source, period:number, units:time_source_units, callback:function, ?args:array, ?reps:int, ?expiryType:time_source_expiry)->void
time_source_get_period(id:time_source)->number
time_source_get_reps_completed(id:time_source)->int
time_source_get_reps_remaining(id:time_source)->int
time_source_get_units(id:time_source)->time_source_units
time_source_get_time_remaining(id:time_source)->number
time_source_get_state(id:time_source)->time_source_state
time_source_get_parent(id:time_source)->time_source
time_source_get_children(id:time_source)->time_source[]
time_source_exists(id:time_source)->bool

time_seconds_to_bpm(seconds:number)->number
time_bpm_to_seconds(bpm:number)->number

time_source_units_seconds#:time_source_units
time_source_units_frames#:time_source_units

time_source_expire_nearest#:time_source_expiry
time_source_expire_after#:time_source_expiry

time_source_state_initial#:time_source_state
time_source_state_active#:time_source_state
time_source_state_paused#:time_source_state
time_source_state_stopped#:time_source_state

call_later(period:number, units:time_source_units, callback:function<void>, ?repeat:bool)->time_source
call_cancel(handle:time_source)->void

audio_bus_main#:audio_bus

??AudioBus
bypass?:bool
gain?:number
effects?:Array<audio_effect>

??AudioEffect
attack?:number
bypass?:bool
cutoff?:number
damp?:number
eq1?:audio_effect
eq2?:audio_effect
eq3?:audio_effect
eq4?:audio_effect
factor?:number
feedback?:number
freq?:number
gain?:number
hicut?:audio_effect
hishelf?:audio_effect
ingain?:number
intensity?:number
locut?:audio_effect
loshelf?:audio_effect
mix?:number
offset?:number
outgain?:number
q?:number
rate?:number
ratio?:number
release?:number
resolution?:number
shape?:audio_lfo_type
size?:number
threshold?:number
time?:number
type?:audio_effect_type

AudioEffectType#:audio_effect_type_enum

AudioLFOType#:audio_lfo_type_enum

audio_bus_create()->audio_bus
audio_effect_create(type:audio_effect_type, ?params:struct)->audio_effect
audio_emitter_bus(emitter:audio_emitter, bus:audio_bus)->void
audio_emitter_get_bus(emitter:audio_emitter)->audio_bus
audio_bus_get_emitters(bus:audio_bus)->audio_emitter[]
audio_bus_clear_emitters(bus:audio_bus)->void

lin_to_db(x:number)->number
db_to_lin(x:number)->number

flexpanel_create_node(?struct:flexpanel_data|struct|string)->flexpanel_node
flexpanel_delete_node(node:flexpanel_node, ?recursive:bool)->void
flexpanel_node_insert_child(parent:flexpanel_node, node:flexpanel_node, index:int)->void
flexpanel_node_remove_child(parent:flexpanel_node, child:flexpanel_node)->void
flexpanel_node_remove_all_children(parent:flexpanel_node)->void
flexpanel_node_get_num_children(parent:flexpanel_node)->int
flexpanel_node_get_child(parent:flexpanel_node, index_or_name:int|string)->flexpanel_node|undefined
flexpanel_node_get_child_hash(parent:flexpanel_node, index_or_name:int|string)->flexpanel_node|undefined
flexpanel_node_get_parent(child:flexpanel_node)->flexpanel_node|undefined
flexpanel_node_get_name(node:flexpanel_node)->string|undefined
flexpanel_node_get_data(node:flexpanel_node)->struct
flexpanel_node_set_name(node:flexpanel_node, name:string)->void
flexpanel_node_set_data(node:flexpanel_node, struct:struct)->void
flexpanel_node_get_struct(node:flexpanel_node)->flexpanel_data
flexpanel_calculate_layout(node:flexpanel_node, width:number|undefined, height:number|undefined, direction:flexpanel_direction_type)->void
flexpanel_node_layout_get_position(node:flexpanel_node, ?relative:bool)->flexpanel_layout
flexpanel_node_style_get_align_content(node:flexpanel_node)->flexpanel_justify_type
flexpanel_node_style_get_align_items(node:flexpanel_node)->flexpanel_align_type
flexpanel_node_style_get_align_self(node:flexpanel_node)->flexpanel_align_type
flexpanel_node_style_get_aspect_ratio(node:flexpanel_node)->number
flexpanel_node_style_get_display(node:flexpanel_node)->flexpanel_display_type
flexpanel_node_style_get_flex(node:flexpanel_node)->number
flexpanel_node_style_get_flex_grow(node:flexpanel_node)->number
flexpanel_node_style_get_flex_shrink(node:flexpanel_node)->number
flexpanel_node_style_get_flex_basis(node:flexpanel_node)->flexpanel_unit_type
flexpanel_node_style_get_flex_direction(node:flexpanel_node)->flexpanel_flex_direction_type
flexpanel_node_style_get_flex_wrap(node:flexpanel_node)->flexpanel_wrap_type
flexpanel_node_style_get_gap(node:flexpanel_node, gutter:flexpanel_gutter_type)->number
flexpanel_node_style_get_position(node:flexpanel_node, edge:flexpanel_edge_type)->flexpanel_unit_value
flexpanel_node_style_get_justify_content(node:flexpanel_node)->flexpanel_justify_type
flexpanel_node_style_get_direction(node:flexpanel_node)->flexpanel_direction_type
flexpanel_node_style_get_margin(node:flexpanel_node, edge:flexpanel_edge_type)->flexpanel_unit_value
flexpanel_node_style_get_padding(node:flexpanel_node, edge:flexpanel_edge_type)->flexpanel_unit_value
flexpanel_node_style_get_border(node:flexpanel_node, edge:flexpanel_edge_type)->flexpanel_unit_value
flexpanel_node_style_get_position_type(node:flexpanel_node)->flexpanel_position
flexpanel_node_style_get_min_width(node:flexpanel_node)->flexpanel_unit_value
flexpanel_node_style_get_max_width(node:flexpanel_node)->flexpanel_unit_value
flexpanel_node_style_get_min_height(node:flexpanel_node)->flexpanel_unit_value
flexpanel_node_style_get_max_height(node:flexpanel_node)->flexpanel_unit_value
flexpanel_node_style_get_width(node:flexpanel_node)->flexpanel_unit_value
flexpanel_node_style_get_height(node:flexpanel_node)->flexpanel_unit_value
flexpanel_node_style_set_align_content(node:flexpanel_node, align:flexpanel_justify_type)->void
flexpanel_node_style_set_align_items(node:flexpanel_node, align:flexpanel_align_type)->void
flexpanel_node_style_set_align_self(node:flexpanel_node, align:flexpanel_align_type)->void
flexpanel_node_style_set_aspect_ratio(node:flexpanel_node, aspect_ratio:number)->void
flexpanel_node_style_set_display(node:flexpanel_node, display:flexpanel_display_type)->void
flexpanel_node_style_set_flex(node:flexpanel_node, flex:number)->void
flexpanel_node_style_set_flex_grow(node:flexpanel_node, grow:number)->void
flexpanel_node_style_set_flex_shrink(node:flexpanel_node, shrink:number)->void
flexpanel_node_style_set_flex_basis(node:flexpanel_node, value:number, unit:flexpanel_unit_value)->void
flexpanel_node_style_set_flex_direction(node:flexpanel_node, direction:flexpanel_flex_direction_type)->void
flexpanel_node_style_set_flex_wrap(node:flexpanel_node, wrap:flexpanel_wrap_type)->void
flexpanel_node_style_set_gap(node:flexpanel_node, gutter:flexpanel_gutter_type, size:number)->void
flexpanel_node_style_set_position(node:flexpanel_node, edge:flexpanel_edge_type, value:number, unit:flexpanel_unit_type)->void
flexpanel_node_style_set_justify_content(node:flexpanel_node, justify:flexpanel_justify_type)->void
flexpanel_node_style_set_direction(node:flexpanel_node, flexpanel_direction:flexpanel_direction_type)->void
flexpanel_node_style_set_margin(node:flexpanel_node, edge:flexpanel_edge_type, value:number)->void
flexpanel_node_style_set_padding(node:flexpanel_node, edge:flexpanel_edge_type, value:number)->void
flexpanel_node_style_set_border(node:flexpanel_node, edge:flexpanel_edge_type, value:number)->void
flexpanel_node_style_set_position_type(node:flexpanel_node, type:flexpanel_position)->void
flexpanel_node_style_set_min_width(node:flexpanel_node, value:number, unit:flexpanel_unit_type)->void
flexpanel_node_style_set_max_width(node:flexpanel_node, value:number, unit:flexpanel_unit_type)->void
flexpanel_node_style_set_min_height(node:flexpanel_node, value:number, unit:flexpanel_unit_type)->void
flexpanel_node_style_set_max_height(node:flexpanel_node, value:number, unit:flexpanel_unit_type)->void
flexpanel_node_style_set_width(node:flexpanel_node, width:number, unit:flexpanel_unit_type)->void
flexpanel_node_style_set_height(node:flexpanel_node, height:number, unit:flexpanel_unit_type)->void