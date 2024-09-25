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
is_instanceof<T:struct>(struct:T, constructor_name:constructor)
is_callable(val:any)->bool
is_handle(val:any)->bool
static_get(struct_or_func_name:struct|function)->struct|undefined
static_set(struct:struct, static_struct:struct)->void
instanceof<T:struct>(struct:T)->string|undefined
exception_unhandled_handler(user_handler:function<Exception;any|void>)

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

method<T:function>(context:instance|struct|undefined,func:T)->T
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
ev_draw_normal#:event_type
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

show_debug_message(val_or_format, ...values)->void
show_debug_message_ext(format:string, values_arr:array)->void
show_debug_overlay(enable:bool,?minimised:bool,?scale:number,?alpha:number)->void
is_debug_overlay_open()->bool
is_mouse_over_debug_overlay()->bool
is_keyboard_used_debug_overlay()->bool
show_debug_log(enable:bool)->void
debug_event(string:string,silent:bool)->struct // TODO ResourceCounts and DumpMemory structs
debug_get_callstack(?maxDepth:int)->string[]

dbg_view(name:string,visible:bool,?x:number,?y:number,?width:number,?height:number)->debug_view
dbg_section(name:string,?open:bool)->debug_section
dbg_view_delete(view:debug_view)->void
dbg_view_exists(view:debug_view)->void
dbg_section_delete(section:debug_section)->bool
dbg_section_exists(section:debug_section)->bool
dbg_slider<T:number>(ref_or_array:debug_reference<T>|debug_reference<T>[],?minimum:number,?maximum:number,?label:string,?step:number)->void
dbg_slider_int<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],?minimum:int,?maximum:int,?label:string,?step:int)->void
dbg_drop_down<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],specifier:string|string[],label:string)->void
dbg_watch<T:any>(ref_or_array:debug_reference<T>|debug_reference<T>[],label:string)->void
dbg_text<T:string>(ref_or_array:T|debug_reference<T>|T[]|debug_reference<T>[])->void
dbg_text_separator<T:string>(ref_or_array:T|debug_reference<T>|T[]|debug_reference<T>[],?align:horizontal_alignment)->void
dbg_sprite<T:sprite>(ref_or_array:debug_reference<T>|debug_reference<T>[],index_ref_or_array:debug_reference<int>|debug_reference<int>[],?label:string,?width:number,?height:number)->void
dbg_text_input<T:string|int|number>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string,?type:string)->void
dbg_checkbox<T:bool>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)->void
dbg_colour<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)£->void
dbg_color<T:int>(ref_or_array:debug_reference<T>|debug_reference<T>[],?label:string)$->void
dbg_button<T:function>(label:string,callback_ref:T|debug_reference<T>,?width:number,?height:number)->void
dbg_sprite_button<T:function,R:sprite>(label:string,callback_ref:T|debug_reference<T>,sprite_ref_or_array:debug_reference<R>|debug_reference<R>[],index_ref_or_array:debug_reference<int>|debug_reference<int>[],?width:number,?height:number,?xoffset:number,?yoffset:number,?widthSprite:number,?heightSprite:number)->void
dbg_same_line()->void
dbg_add_font_glyphs(filename_ttf:string,?size:number,?font_range:int)->void
ref_create<T>(context:instance|struct|debug_reference<instance>|debug_reference<struct>,name:string|debug_reference<string>,?index:int)->debug_reference<T>

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
sequence_instance@:sequence_instance

#endregion

//////////////
// Chapter 406
//////////////

#region 6.3
audio_system()&->void
audio_play_sound(soundid:sound,priority:int,loops:bool,?gain:real,?offset:real,?pitch:real,?listener_mask:int)->sound_instance
audio_play_sound_on(emitterid:audio_emitter,soundid:sound,loops:bool,priority:int,?gain:real,?offset:real,?pitch:real,?listener_mask:int)->sound_instance
audio_play_sound_at(soundid:sound,x:number,y:number,z:number, falloff_ref_dist:number,falloff_max_dist:number,falloff_factor:number,loops:bool, priority:int,?gain:real,?offset:real,?pitch:real,?listener_mask:int)-
audio_play_sound_ext(params:any_fields_of<audio_play_sound_ext_t>)->sound_instance
#endregion

//////////////
// Chapter 407
//////////////

//////////////
// Chapter 408
//////////////

//////////////
// Chapter 409
//////////////

#region 9.4
font_enable_sdf(ind:font,enable:bool)
font_get_sdf_enabled(ind:font)->bool
font_texture_page_size:int
#endregion

#region 9.6

script_execute_ext(ind:script,?args:any[],offset:int=0,num_args:int=args_length-offset)->any

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

os_gdk#:os_type
os_operagx#:os_type
os_gxgames#:os_type

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

json_stringify<T:struct|array|number|string|undefined>(val:T,?prettify:bool)->string
json_parse(json:string)->any

network_socket_ws#:network_type
network_config_avoid_time_wait#:network_config
buffer_surface_copy&:any
buffer_get_surface(buffer:buffer, source_surface:surface,offset:int)->void
buffer_set_surface(buffer:buffer, dest_surface:surface,offset:int)->void


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


// SequenceInstance properties
??SequenceInstance
sequence?:sequence_object
headPosition?:int
headDirection?:sequence_direction
speedScale?:number
volume?:number
paused?:bool
finished?:bool
activeTracks?:sequence_active_track[]
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
tracks?:sequence_track[]
messageEventKeyframes?:sequence_keyframe[]
momentKeyframes?:sequence_keyframe[]
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
tracks?:sequence_track[]
interpolation?:sequence_interpolation
enabled?:bool
visible?:bool
linked? // deprecated
linkedTrack? // deprecated
keyframes?:sequence_keyframe[]

// Keyframe properties
??Keyframe
frame?:int
length?:int
stretch?:bool
disabled? // deprecated
channels?:sequence_keyframe_data[]

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
alignmentV?
alignmentH?
fontIndex?:font
effectsEnabled?:bool
glowEnabled?:bool
outlineEnabled?:bool
dropShadowEnabled?:bool

// Message event
??MessageEvent
events?:string[]

// Moment key
??Moment
event?:function
{}

// AnimCurve properties
??AnimCurve
name?:string
graphType?:int
channels?:animcurve_channel[]

// AnimCurveChannel properties
??AnimCurveChannel
type?:animcurve_interpolation
iterations?:int
points?:animcurve_point[]

// AnimCurvePoint properties
??AnimCurvePoint
posx?:number
value?:number

// TrackEvalNode properties
??TrackEvalNode
activeTracks?:sequence_track[]
matrix?:number[]
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
colormultiply?:tuple<number,number,number,number>
colourmultiply?:tuple<number,number,number,number>
coloradd?:tuple<number,number,number,number>
colouradd?:tuple<number,number,number,number>
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
coreColor?:tuple<number,number,number,number>
coreColour?:tuple<number,number,number,number>
glowStart?:number
glowEnd?:number
glowColor?:tuple<number,number,number,number>
glowColour?:tuple<number,number,number,number>
outlineDist?:number
outlineColor?:tuple<number,number,number,number>
outlineColour?:tuple<number,number,number,number>
shadowSoftness?:number
shadowOffsetX?:number
shadowOffsetY?:number
shadowColor?:tuple<number,number,number,number>
shadowColour?:tuple<number,number,number,number>
effectsEnabled?:bool
glowEnabled?:bool
outlineEnabled?:bool
dropShadowEnabled?:bool
track?:sequence_track
parent?:sequence_instance
activeTracks?:sequence_active_track

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


time_source_create(parent:time_source, period:number, units:time_source_units, callback:function, ?args:array, ?reps:number, ?expiryType:time_source_expiry)->time_source
time_source_destroy(id:time_source, [destroyTree:bool])
time_source_start(id:time_source)
time_source_stop(id:time_source)
time_source_pause(id:time_source)
time_source_resume(id:time_source)
time_source_reset(id:time_source)
time_source_reconfigure(id:time_source, period:number, units:time_source_units, callback:function, ?args:array, ?reps:number, ?expiryType:time_source_expiry)
time_source_get_period(id:time_source)->number
time_source_get_reps_completed(id:time_source)->number
time_source_get_reps_remaining(id:time_source)->number
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

call_later(period:number, units:time_source_units, callback:function<void>, [repeat:bool])->time_source
call_cancel(handle:time_source)