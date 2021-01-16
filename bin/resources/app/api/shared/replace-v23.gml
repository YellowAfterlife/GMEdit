//////////////
// Chapter 401
//////////////

// # = constant
// * = readonly
// @ = instance variable
// & = obsolete
// $ = US spelling
// £ = UK spelling
// ! = disallowed in free
// % = property
// ? = struct variable

// TODO these down here
argument_relative&
argument
argument0
argument1
argument2
argument3
argument4
argument5
argument6
argument7
argument8
argument9
argument10
argument11
argument12
argument13
argument14
argument15
argument_count:int
self#
other#
all#
noone#
global#
undefined#
pointer_invalid#
pointer_null#

path_action_stop#:path_endaction
path_action_restart#:path_endaction
path_action_continue#:path_endaction
path_action_reverse#:path_endaction


//////////////
// Chapter 402
//////////////

// section 2.1

true#:bool
false#:bool
pi#:number
NaN#:number
infinity#:number
GM_build_date#:datetime
GM_version#:string
GM_runtime_version#:string

// section 2.2

is_real(val:any)->bool
is_numeric(val:any)->bool
is_string(val:any)->bool
is_array(val:any)->bool
is_undefined(val:any)->bool
is_int32(val:any)->bool
is_int64(val:any)->bool
is_ptr(val:any)->bool
is_vec3(val:any)->bool
is_vec4(val:any)->bool
is_matrix(val:any)&->bool
is_bool(val:any)->bool
is_nan(val:any)->bool
is_infinity(val:any)->bool
is_struct(val:any)->bool
is_method(val:any)->bool
typeof(val:any)->bool
instanceof<T>(struct:T)->bool // where T:struct
exception_unhandled_handler(user_handler) // TODO
variable_global_exists(name:string)->bool
variable_global_get(name:string)->any
variable_global_set(name:string,val:any)->void
variable_instance_exists<T>(id:T,name:string)->bool // where T:instance
variable_instance_get<T>(id:T,name:string)->any // where T:instance
variable_instance_set<T>(id:T,name:string,val:any)->void // where T:instance
variable_instance_get_names<T>(id:T)->Array<string> // where T:instance
variable_instance_names_count<T>(id:T)->int // where T:instance
variable_struct_exists<T>(struct:T,name:string)->bool // where T:struct
variable_struct_get<T>(struct:T,name:string)->any // where T:struct
variable_struct_set<T>(struct:T,name:string,val:any)->void // where T:struct
variable_struct_get_names<T>(struct:T)->Array<string> // where T:struct
variable_struct_names_count<T>(struct:T)->int // where T:struct
variable_struct_remove<T>(struct:T,name:string)->void // where T:struct
array_length<T>(variable:Array<T>)->int
array_length_1d<T>(variable:Array<T>)&->int
array_length_2d<T>(variable:Array<T>, index:int)&->int
array_height_2d<T>(variable:Array<T>)&->int
array_equals<T0, T1>(var1:Array<T0>,var2:Array<T1>)->bool
array_create(size:int, [value]) // TODO
array_copy<T>(dest:Array<T>,dest_index:int,src:Array<T>,src_index:int,length:int)->void
array_resize<T>(variable:Array<T>,newsize:int)->void
array_get<T>(variable:Array<T>,index:int)->any
array_set<T>(variable:Array<T>,index:int,val:any)->void
array_push<T>(array:Array<T>,...values:T)->void
array_pop<T>(array:Array<T>)->T
array_insert<T>(array:Array<T>,index:int,...values:T)->void
array_delete<T>(array:Array<T>,index:int,number:int)->void
array_sort<T>(array:Array<T>,sortType_or_function:bool)->void //TODO function is untyped
random(x:number)->number
random_range(x1:number,x2:number)->number
irandom(x:int)->int
irandom_range(x1:int,x2:int)->int
random_set_seed(seed:int)->void
random_get_seed()->int
randomize()$->void
randomise()£->void
choose<T>(...values:T)->T
abs(x:number)->number
round(x:number)->int
floor(x:number)->int
ceil(x:number)->int
sign(x:number)->int
frac(x:number)->number
sqrt(x:number)->number
sqr(x:number)->number
exp(x:number)->number
ln(x:number)->number
log2(x:number)->number
log10(x:number)->number
sin(radian_angle:number)->number
cos(radian_angle:number)->number
tan(radian_angle:number)->number
arcsin(x:number)->number
arccos(x:number)->number
arctan(x:number)->number
arctan2(y:number,x:number)->number
dsin(degree_angle:number)->number
dcos(degree_angle:number)->number
dtan(degree_angle:number)->number
darcsin(x:number)->number
darccos(x:number)->number
darctan(x:number)->number
darctan2(y:number,x:number)->number
degtorad(x:number)->number
radtodeg(x:number)->number
power(x:number,n:number)->number
logn(n:number,x:number)->number
min(...values:number)->number
max(...values:number)->number
mean(...values:number)->number
median(...values:number)->number
clamp(val:number,min:number,max:number)->number
lerp(val1:number,val2:number,amount:number)->number
dot_product(x1:number,y1:number,x2:number,y2:number)->number
dot_product_3d(x1:number,y1:number,z1:number,x2:number,y2:number,z2:number)->number
dot_product_normalised(x1:number,y1:number,x2:number,y2:number)£->number
dot_product_3d_normalised(x1:number,y1:number,z1:number,x2:number,y2:number,z2:number)£->number
dot_product_normalized(x1:number,y1:number,x2:number,y2:number)$->number
dot_product_3d_normalized(x1:number,y1:number,z1:number,x2:number,y2:number,z2:number)$->number
math_set_epsilon(new_epsilon:number)->void
math_get_epsilon()->number
angle_difference(src:number,dest:number)->number
point_distance_3d(x1:number,y1:number,z1:number,x2:number,y2:number,z2:number)->number
point_distance(x1:number,y1:number,x2:number,y2:number)->number
point_direction(x1:number,y1:number,x2:number,y2:number)->number
lengthdir_x(len:number,dir:number)->number
lengthdir_y(len:number,dir:number)->number

weak_ref_create<T>(thing_to_track:T)->weak_reference // where T:struct
weak_ref_alive(weak_ref:weak_reference)->bool
weak_ref_any_alive(array:Array<weak_reference>,[index]:int,[length]:int)->bool

// section 2.3

real(val:string)->number
bool(val:number)->bool
string(val:any)->string
int64(val:number)->int
ptr(val:number|string)->pointer
string_format(val:number,total:int,dec:int)->string
chr(val:int)->string
ansi_char(val:int)->string
ord(char:string)->int
method(struct_ref_or_instance_id,func) //TODO
method_get_index(method) //TODO
method_get_self(method) //TODO
string_length(str:string)->int
string_byte_length(str:string)->int
string_pos(substr:string,str:string)->int
string_pos_ext(substr:string,str:string,startpos:int)->int
string_last_pos(substr:string,str:string)->int
string_last_pos_ext(substr:string,str:string,startpos:int)->int
string_copy(str:string,index:int,count:int)->int
string_char_at(str:string,index:int)->string
string_ord_at(str:string,index:int)->int
string_byte_at(str:string,index:int)->int
string_set_byte_at(str:string,index:int,val:int)->string
string_delete(str:string,index:int,count:int)->string
string_insert(substr:string,str:string,index:int)->string
string_lower(str:string)->string
string_upper(str:string)->string
string_repeat(str:string,count:int)->string
string_letters(str:string)->string
string_digits(str:string)->string
string_lettersdigits(str:string)->string
string_replace(str:string,substr:string,newstr:string)->string
string_replace_all(str:string,substr:string,newstr:string)->string
string_count(substr:string,str:string)->int
string_hash_to_newline(str:string)->string
clipboard_has_text()->bool
clipboard_set_text(str:string)->void
clipboard_get_text()->string

// section 2.4

date_current_datetime()->datetime
date_create_datetime(year:int,month:int,day:int,hour:int,minute:int,second:int)->datetime
date_valid_datetime(year:int,month:int,day:int,hour:int,minute:int,second:int)->bool
date_inc_year(date:datetime,amount:int)->datetime
date_inc_month(date:datetime,amount:int)->datetime
date_inc_week(date:datetime,amount:int)->datetime
date_inc_day(date:datetime,amount:int)->datetime
date_inc_hour(date:datetime,amount:int)->datetime
date_inc_minute(date:datetime,amount:int)->datetime
date_inc_second(date:datetime,amount:int)->datetime
date_get_year(date:datetime)->int
date_get_month(date:datetime)->int
date_get_week(date:datetime)->int
date_get_day(date:datetime)->int
date_get_hour(date:datetime)->int
date_get_minute(date:datetime)->int
date_get_second(date:datetime)->int
date_get_weekday(date:datetime)->int
date_get_day_of_year(date:datetime)->int
date_get_hour_of_year(date:datetime)->int
date_get_minute_of_year(date:datetime)->int
date_get_second_of_year(date:datetime)->int
date_year_span(date1:datetime,date2:datetime)->int
date_month_span(date1:datetime,date2:datetime)->int
date_week_span(date1:datetime,date2:datetime)->int
date_day_span(date1:datetime,date2:datetime)->int
date_hour_span(date1:datetime,date2:datetime)->int
date_minute_span(date1:datetime,date2:datetime)->int
date_second_span(date1:datetime,date2:datetime)->int
date_compare_datetime(date1:datetime,date2:datetime)->int
date_compare_date(date1:datetime,date2:datetime)->int
date_compare_time(date1:datetime,date2:datetime)->int
date_date_of(date:datetime)->datetime
date_time_of(date:datetime)->datetime
date_datetime_string(date:datetime)->string
date_date_string(date:datetime)->string
date_time_string(date:datetime)->string
date_days_in_month(date:datetime)->int
date_days_in_year(date:datetime)->int
date_leap_year(date:datetime)->bool
date_is_today(date:datetime)->bool

date_set_timezone(timezone:timezone_type)->void
date_get_timezone()->timezone_type
timezone_local#:timezone_type
timezone_utc#:timezone_type

game_set_speed(value:number,type:gamespeed_type)->void
game_get_speed(type:gamespeed_type)->number
gamespeed_fps#:gamespeed_type
gamespeed_microseconds#:gamespeed_type

//////////////
// Chapter 403
//////////////

// section 3.1

x@:number
y@:number
xprevious@:number
yprevious@:number
xstart@:number
ystart@:number
hspeed@:number
vspeed@:number
direction@:number
speed@:number
friction@:number
gravity@:number
gravity_direction@:number
in_collision_tree@:bool
motion_set(dir:number,speed:number)->void
motion_add(dir:number,speed:number)->void
place_free(x:number,y:number)->bool
place_empty<T>(x:number,y:number,obj:T)->bool // where T:object|instance
place_meeting<T>(x:number,y:number,obj:T)->bool // where T:object|instance
place_snapped(hsnap:number,vsnap:number)->bool
move_random(hsnap:number,vsnap:number)->void
move_snap(hsnap:number,vsnap:number)->void
move_towards_point(x:number,y:number,sp:number)->void
move_contact_solid(dir:number,maxdist:number)->void
move_contact_all(dir:number,maxdist:number)->void
move_outside_solid(dir:number,maxdist:number)->void
move_outside_all(dir:number,maxdist:number)->void
move_bounce_solid(advanced:bool)->void
move_bounce_all(advanced:bool)->void
move_wrap(hor:number,vert:number,margin:number)->void
distance_to_point(x:number,y:number)->number
distance_to_object<T>(obj:T)->number // where T:object|instance
position_empty(x:number,y:number)->bool
position_meeting<T>(x:number,y:number,obj:T)->bool // where T:object|instance

// section 3.2

path_start(path:path,speed:number,endaction:path_endaction,absolute:bool)->void
path_end()->void
path_index*@:path
path_position@:number
path_positionprevious@:number
path_speed@:number
path_scale@:number
path_orientation@:number
path_endaction@:path_endaction

// section 3.3

mp_linear_step(x:number,y:number,speed:number,checkall:bool)->bool
mp_potential_step(x:number,y:number,speed:number,checkall:bool)->bool
mp_linear_step_object<T>(x:number,y:number,speed:number,obj:T)->bool // where T:object|instance
mp_potential_step_object<T>(x:number,y:number,speed:number,obj:T)->bool // where T:object|instance
mp_potential_settings(maxrot:number,rotstep:number,ahead:int,onspot:bool)->void
mp_linear_path(path:path,xg:number,yg:number,stepsize:number,checkall:bool)->bool
mp_potential_path(path:path,xg:number,yg:number,stepsize:number,factor:int,checkall:bool)->bool
mp_linear_path_object<T>(path:path,xg:number,yg:number,stepsize:number,obj:T)->bool // where T:object|instance
mp_potential_path_object<T>(path:path,xg:number,yg:number,stepsize:number,factor:int,obj:T)->bool // where T:object|instance
mp_grid_create(left:number,top:number,hcells:int,vcells:int,cellwidth:number,cellheight:number)->mp_grid
mp_grid_destroy(id:mp_grid)->void
mp_grid_clear_all(id:mp_grid)->void
mp_grid_clear_cell(id:mp_grid,h:int,v:int)->void
mp_grid_clear_rectangle(id:mp_grid,left:int,top:int,right:int,bottom:int)->void
mp_grid_add_cell(id:mp_grid,h:int,v:int)->void
mp_grid_get_cell(id:mp_grid,h:int,v:int)->int
mp_grid_add_rectangle(id:mp_grid,left:int,top:int,right:int,bottom:int)->void
mp_grid_add_instances<T>(id:mp_grid,obj:T,prec:bool)->void // where T:object|instance
mp_grid_path(id:mp_grid,path:path,xstart:number,ystart:number,xgoal:number,ygoal:number,allowdiag:bool)->bool
mp_grid_draw(id:mp_grid)->void
mp_grid_to_ds_grid(src:mp_grid,dest:ds_grid<number>)->bool

// section 3.4

collision_point<T>(x:number,y:number,obj:T,prec:bool,notme:bool)->T // where T:object|instance
collision_rectangle<T>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool)->T // where T:object|instance
collision_circle<T>(x1:number,y1:number,radius:number,obj:T,prec:bool,notme:bool)->T // where T:object|instance
collision_ellipse<T>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool)->T // where T:object|instance
collision_line<T>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool)->T // where T:object|instance

collision_point_list<T>(x:number,y:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int // where T:object|instance
collision_rectangle_list<T>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int // where T:object|instance
collision_circle_list<T>(x1:number,y1:number,radius:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int // where T:object|instance
collision_ellipse_list<T>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int // where T:object|instance
collision_line_list<T>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int // where T:object|instance
instance_position_list<T>(x:number,y:number,obj:T,list:ds_list<T>,ordered:bool)->int // where T:object|instance
instance_place_list<T>(x:number,y:number,obj:T,list:ds_list<T>,ordered:bool)->int // where T:object|instance

point_in_rectangle(px:number,py:number,x1:number,y1:number,x2:number,y2:number)->bool
point_in_triangle(px:number,py:number,x1:number,y1:number,x2:number,y2:number,x3:number,y3:number)->bool
point_in_circle(px:number,py:number,cx:number,cy:number,rad:number)->bool
rectangle_in_rectangle(sx1:number,sy1:number,sx2:number,sy2:number,dx1:number,dy1:number,dx2:number,dy2:number)->bool
rectangle_in_triangle(sx1:number,sy1:number,sx2:number,sy2:number,x1:number,y1:number,x2:number,y2:number,x3:number,y3:number)->bool
rectangle_in_circle(sx1:number,sy1:number,sx2:number,sy2:number,cx:number,cy:number,rad:number)->bool


// section 3.5

object_index*@ // TODO
id*@ // TODO
solid@:bool
persistent@:bool
mask_index@:sprite
instance_count*@:int
instance_id*@ // TODO
instance_find<T>(obj:T,n:int)->T // where T:object
instance_exists<T>(obj:T)->bool // where T:object|instance
instance_number<T>(obj:T)->bool // where T:object
instance_position<T>(x:number,y:number,obj:T)->T // where T:object|instance
instance_nearest<T>(x:number,y:number,obj:T)->T // where T:object|instance
instance_furthest<T>(x:number,y:number,obj:T)->T // where T:object|instance
instance_place<T>(x:number,y:number,obj:T)->T // where T:object|instance
instance_create_depth<T>(x:number,y:number,depth:number,obj:T)->T // where T:object
instance_create_layer<T>(x:number,y:number,layer_id_or_name:layer|string,obj:T)-> // where T:object
instance_copy(performevent) // TODO... good luck with this one
instance_change<T>(obj:T,performevents:bool)->void // where T:object|instance
instance_destroy<T>(id*:T,execute_event_flag*:bool)->void // where T:object|instance
position_destroy(x:number,y:number)->void
position_change<T>(x:number,y:number,obj:T,performevents:bool)->void // where T:object
instance_id_get(index:int)->any // where any:instance

// section 3.6

instance_deactivate_all(notme:bool)->void
instance_deactivate_object<T>(obj:T)->void // where T:object|instance
instance_deactivate_region(left:number,top:number,width:number,height:number,inside:bool,notme:bool)->void
instance_activate_all()->void
instance_activate_object<T>(obj:T)->void // where T:object|instance
instance_activate_region(left:number,top:number,width:number,height:number,inside:bool)->void

// section 3.7

room_speed:number
fps*:number
fps_real*:number
current_time*:int
current_year*:int
current_month*:int
current_day*:int
current_weekday*:int
current_hour*:int
current_minute*:int
current_second*:int
alarm[0..11]@ // TODO
timeline_index@:timeline
timeline_position@:number
timeline_speed@:number
timeline_running@:bool
timeline_loop@:bool

// section 3.8

room:room
room_first*:room
room_last*:room
room_width*:int
room_height*:int
room_caption&:string
room_persistent:bool
room_goto(numb:room)->void
room_goto_previous()->void
room_goto_next()->void
room_previous(numb:room)->room
room_next(numb:room)->room
room_restart()->void
game_end()->void
game_restart()->void
game_load(filename:string)->void
game_save(filename:string)->void
game_save_buffer(buffer:buffer)->void
game_load_buffer(buffer:buffer)->void


// section 3.9

score:number
lives:number
health:number
show_score& // TODO what are these?
show_lives&
show_health&
caption_score&
caption_lives&
caption_health&

// section 3.10

event_perform<T>(type:event_type,numb:int|event_number|T)->void // where T:object
event_user(numb:int)->void
event_perform_object<T0, T1>(obj:T0,type:event_type,numb:int|event_number|T1)->void // where T0:object, T1:object
event_inherited()->void
event_type*:any
event_number*:int|event_number
event_object*:any // where any:object
event_action*:int
ev_create#:event_type
ev_destroy#:event_type
ev_step#:event_type
ev_alarm#:event_type
ev_keyboard#:event_type
ev_mouse#:event_type
ev_collision#:event_type
ev_other#:event_type
ev_draw#:event_type
ev_draw_begin#:event_number
ev_draw_end#:event_number
ev_draw_pre#:event_number
ev_draw_post#:event_number
ev_keypress#:event_type
ev_keyrelease#:event_type
ev_trigger# // TODO literally can't find this
ev_left_button#:event_number
ev_right_button#:event_number
ev_middle_button#:event_number
ev_no_button#:event_number
ev_left_press#:event_number
ev_right_press#:event_number
ev_middle_press#:event_number
ev_left_release#:event_number
ev_right_release#:event_number
ev_middle_release#:event_number
ev_mouse_enter#:event_number
ev_mouse_leave#:event_number
ev_mouse_wheel_up#:event_number
ev_mouse_wheel_down#:event_number
ev_global_left_button#:event_number
ev_global_right_button#:event_number
ev_global_middle_button#:event_number
ev_global_left_press#:event_number
ev_global_right_press#:event_number
ev_global_middle_press#:event_number
ev_global_left_release#:event_number
ev_global_right_release#:event_number
ev_global_middle_release#:event_number
ev_joystick1_left#:event_number
ev_joystick1_right#:event_number
ev_joystick1_up#:event_number
ev_joystick1_down#:event_number
ev_joystick1_button1#:event_number
ev_joystick1_button2#:event_number
ev_joystick1_button3#:event_number
ev_joystick1_button4#:event_number
ev_joystick1_button5#:event_number
ev_joystick1_button6#:event_number
ev_joystick1_button7#:event_number
ev_joystick1_button8#:event_number
ev_joystick2_left#:event_number
ev_joystick2_right#:event_number
ev_joystick2_up#:event_number
ev_joystick2_down#:event_number
ev_joystick2_button1#:event_number
ev_joystick2_button2#:event_number
ev_joystick2_button3#:event_number
ev_joystick2_button4#:event_number
ev_joystick2_button5#:event_number
ev_joystick2_button6#:event_number
ev_joystick2_button7#:event_number
ev_joystick2_button8#:event_number
ev_outside#:event_number
ev_boundary#:event_number
ev_game_start#:event_number
ev_game_end#:event_number
ev_room_start#:event_number
ev_room_end#:event_number
ev_no_more_lives#:event_number
ev_animation_end#:event_number
ev_end_of_path#:event_number
ev_no_more_health#:event_number
ev_close_button&:event_number
ev_user0#:event_number
ev_user1#:event_number
ev_user2#:event_number
ev_user3#:event_number
ev_user4#:event_number
ev_user5#:event_number
ev_user6#:event_number
ev_user7#:event_number
ev_user8#:event_number
ev_user9#:event_number
ev_user10#:event_number
ev_user11#:event_number
ev_user12#:event_number
ev_user13#:event_number
ev_user14#:event_number
ev_user15#:event_number
ev_outside_view0#:event_number
ev_outside_view1#:event_number
ev_outside_view2#:event_number
ev_outside_view3#:event_number
ev_outside_view4#:event_number
ev_outside_view5#:event_number
ev_outside_view6#:event_number
ev_outside_view7#:event_number
ev_boundary_view0#:event_number
ev_boundary_view1#:event_number
ev_boundary_view2#:event_number
ev_boundary_view3#:event_number
ev_boundary_view4#:event_number
ev_boundary_view5#:event_number
ev_boundary_view6#:event_number
ev_boundary_view7#:event_number
ev_animation_update#:event_number
ev_animation_event#:event_number
ev_web_image_load#:event_number
ev_web_sound_load#:event_number
ev_web_async#:event_number
ev_dialog_async#:event_number
ev_web_iap#:event_number
ev_web_cloud#:event_number
ev_web_networking#:event_number
ev_web_steam#:event_number
ev_social#:event_number
ev_push_notification#:event_number
ev_async_save_load#:event_number
ev_audio_recording#:event_number
ev_audio_playback#:event_number
ev_system_event#:event_number
ev_broadcast_message#:event_number
ev_step_normal#:event_number
ev_step_begin#:event_number
ev_step_end#:event_number
ev_gui#:event_number
ev_gui_begin#:event_number
ev_gui_end#:event_number
ev_cleanup#:event_type

ev_gesture#:event_type

ev_gesture_tap#:event_number
ev_gesture_double_tap#:event_number
ev_gesture_drag_start#:event_number
ev_gesture_dragging#:event_number
ev_gesture_drag_end#:event_number
ev_gesture_flick#:event_number
ev_gesture_pinch_start#:event_number
ev_gesture_pinch_in#:event_number
ev_gesture_pinch_out#:event_number
ev_gesture_pinch_end#:event_number
ev_gesture_rotate_start#:event_number
ev_gesture_rotating#:event_number
ev_gesture_rotate_end#:event_number

ev_global_gesture_tap#:event_number
ev_global_gesture_double_tap#:event_number
ev_global_gesture_drag_start#:event_number
ev_global_gesture_dragging#:event_number
ev_global_gesture_drag_end#:event_number
ev_global_gesture_flick#:event_number
ev_global_gesture_pinch_start#:event_number
ev_global_gesture_pinch_in#:event_number
ev_global_gesture_pinch_out#:event_number
ev_global_gesture_pinch_end#:event_number
ev_global_gesture_rotate_start#:event_number
ev_global_gesture_rotating#:event_number
ev_global_gesture_rotate_end#:event_number

// section 3.11

application_surface*:surface
gamemaker_pro&:bool
gamemaker_registered&:bool
gamemaker_version&:bool
error_occurred&:bool
error_last&:any
show_debug_message(str:any)->void
show_debug_overlay(enable:bool)->void
debug_mode*:bool
debug_event(str:string)->void
debug_get_callstack()->Array<string>
alarm_get(index:int)->int
alarm_set(index:int,count:int)->void

font_texture_page_size:int

//////////////
// Chapter 404
//////////////

// section 4.1

keyboard_key:int
keyboard_lastkey:int
keyboard_lastchar:string
keyboard_string:string
keyboard_set_map(key1:int,key2:int)->void
keyboard_get_map(key:int)->int
keyboard_unset_map()->void
keyboard_check(key:int)->bool
keyboard_check_pressed(key:int)->bool
keyboard_check_released(key:int)->bool
keyboard_check_direct(key:int)->bool
keyboard_get_numlock()->bool
keyboard_set_numlock(on:bool)->void
keyboard_key_press(key:int)->void
keyboard_key_release(key:int)->void
vk_nokey#:int
vk_anykey#:int
vk_enter#:int
vk_return#:int
vk_shift#:int
vk_control#:int
vk_alt#:int
vk_escape#:int
vk_space#:int
vk_backspace#:int
vk_tab#:int
vk_pause#:int
vk_printscreen#:int
vk_left#:int
vk_right#:int
vk_up#:int
vk_down#:int
vk_home#:int
vk_end#:int
vk_delete#:int
vk_insert#:int
vk_pageup#:int
vk_pagedown#:int
vk_f1#:int
vk_f2#:int
vk_f3#:int
vk_f4#:int
vk_f5#:int
vk_f6#:int
vk_f7#:int
vk_f8#:int
vk_f9#:int
vk_f10#:int
vk_f11#:int
vk_f12#:int
vk_numpad0#:int
vk_numpad1#:int
vk_numpad2#:int
vk_numpad3#:int
vk_numpad4#:int
vk_numpad5#:int
vk_numpad6#:int
vk_numpad7#:int
vk_numpad8#:int
vk_numpad9#:int
vk_divide#:int
vk_multiply#:int
vk_subtract#:int
vk_add#:int
vk_decimal#:int
vk_lshift#:int
vk_lcontrol#:int
vk_lalt#:int
vk_rshift#:int
vk_rcontrol#:int
vk_ralt#:int
keyboard_clear(key:int)->bool
io_clear()->void

// section 4.2

mouse_x*:number
mouse_y*:number
mouse_button:mouse_button
mouse_lastbutton:mouse_button
mb_any#:mouse_button
mb_none#:mouse_button
mb_left#:mouse_button
mb_right#:mouse_button
mb_middle#:mouse_button
mouse_check_button(button:mouse_button)->bool
mouse_check_button_pressed(button:mouse_button)->bool
mouse_check_button_released(button:mouse_button)->bool
mouse_wheel_up()->bool
mouse_wheel_down()->bool
mouse_clear(button:mouse_button)->bool
cursor_sprite:sprite

//////////////
// Chapter 405
//////////////

// section 5.1

visible@:bool
sprite_index@:sprite
sprite_width*@:int
sprite_height*@:int
sprite_xoffset*@:number
sprite_yoffset*@:number
image_number*@:int
image_index@:number
image_speed@:number
depth@:number
image_xscale@:number
image_yscale@:number
image_angle@:number
image_alpha@:number
image_blend@:number
bbox_left*@:number
bbox_right*@:number
bbox_top*@:number
bbox_bottom*@:number

bboxmode_automatic#:bbox_mode
bboxmode_fullimage#:bbox_mode
bboxmode_manual#:bbox_mode

bboxkind_precise#:bbox_kind
bboxkind_rectangular#:bbox_kind
bboxkind_ellipse#:bbox_kind
bboxkind_diamond#:bbox_kind

// exception structure entries
message*@:string
longMessage*@:string
script*@:script
stacktrace*@:Array<string>


// Layer-related built-in variables
layer@:layer

// Sequence-related built-ins
in_sequence@:bool
sequence_instance@ //TODO

// section 5.2

background_colour£:int
background_showcolour£:bool
background_color$:int
background_showcolor$:bool

// section 5.3

draw_self()->void
draw_sprite(sprite:sprite,subimg:number,x:number,y:number)->void
draw_sprite_pos(sprite:sprite,subimg:number,x1:number,y1:number,x2:number,y2:number,x3:number,y3:number,x4:number,y4:number,alpha:number)->void
draw_sprite_ext(sprite:sprite,subimg:number,x:number,y:number,xscale:number,yscale:number,rot:number,col:int,alpha:number)->void
draw_sprite_stretched(sprite:sprite,subimg:number,x:number,y:number,w:number,h:number)->void
draw_sprite_stretched_ext(sprite:sprite,subimg:number,x:number,y:number,w:number,h:number,col:int,alpha:number)->void
draw_sprite_tiled(sprite:sprite,subimg:number,x:number,y:number)->void
draw_sprite_tiled_ext(sprite:sprite,subimg:number,x:number,y:number,xscale:number,yscale:number,col:int,alpha:number)->void
draw_sprite_part(sprite:sprite,subimg:number,left:number,top:number,width:number,height:number,x:number,y:number)->void
draw_sprite_part_ext(sprite:sprite,subimg:number,left:number,top:number,width:number,height:number,x:number,y:number,xscale:number,yscale:number,col:int,alpha:number)->void
draw_sprite_general(sprite:sprite,subimg:number,left:number,top:number,width:number,height:number,x:number,y:number,xscale:number,yscale:number,rot:number,c1:int,c2:int,c3:int,c4:int,alpha:number)->void

// section 5.4

draw_clear(col:int)->void
draw_clear_alpha(col:int,alpha:number)->void
draw_point(x:number,y:number)->void
draw_line(x1:number,y1:number,x2:number,y2:number)->void
draw_line_width(x1:number,y1:number,x2:number,y2:number,w:number)->void
draw_rectangle(x1:number,y1:number,x2:number,y2:number,outline:bool)->void
draw_roundrect(x1:number,y1:number,x2:number,y2:number,outline:number)->void
draw_roundrect_ext(x1:number,y1:number,x2:number,y2:number,radiusx:number,radiusy:number,outline:bool)->void
draw_triangle(x1:number,y1:number,x2:number,y2:number,x3:number,y3:number,outline:bool)->void
draw_circle(x:number,y:number,r:number,outline:bool)->void
draw_ellipse(x1:number,y1:number,x2:number,y2,outline:bool)->void
draw_set_circle_precision(precision:int)->void
draw_arrow(x1:number,y1:number,x2:number,y2:number,size:number)->void
draw_button(x1:number,y1:number,x2:number,y2:number,up:bool)->void
draw_path(path:path,x:number,y:number,absolute:bool)->void
draw_healthbar(x1:number,y1:number,x2:number,y2:number,amount:number,backcol:int,mincol:int,maxcol:int,direction:number,showback:bool,showborder:bool)->void
draw_getpixel(x:number,y:number)->int
draw_getpixel_ext(x:number,y:number)->int
draw_set_colour(col:int)£->void
draw_set_color(col:int)$->void
draw_set_alpha(alpha:number)->void
draw_get_colour()£->int
draw_get_color() $->int
draw_get_alpha()->number
c_aqua#:int
c_black#:int
c_blue#:int
c_dkgray#:int
c_dkgrey#:int
c_fuchsia#:int
c_gray#:int
c_grey#:int
c_green#:int
c_lime#:int
c_ltgray#:int
c_ltgrey#:int
c_maroon#:int
c_navy#:int
c_olive#:int
c_purple#:int
c_red#:int
c_silver#:int
c_teal#:int
c_white#:int
c_yellow#:int
c_orange#:int
merge_colour(col1:int,col2:int,amount:number)£->int
make_colour_rgb(red:int,green:int,blue:int)£->int
make_colour_hsv(hue:number,saturation:number,value:number)£->int
colour_get_red(col:int)£->int
colour_get_green(col:int)£->int
colour_get_blue(col:int)£->int
colour_get_hue(col:int)£->number
colour_get_saturation(col:int)£->number
colour_get_value(col:int)£->number
merge_color(col1:int,col2:int,amount->number)$
make_color_rgb(red:int,green:int,blue:int)$->int
make_color_hsv(hue:number,saturation:number,value:number)$->int
color_get_red(col:int)$->int
color_get_green(col:int)$->int
color_get_blue(col:int)$->int
color_get_hue(col:int)$->number
color_get_saturation(col:int)$->number
color_get_value(col:int)$->number
screen_save(fname:string)->void
screen_save_part(fname:string,x:number,y:number,w:int,h:int)->void
gif_open(width:int,height:int,clear_color:int)->gif
gif_add_surface(gifindex:gif,surfaceindex:surface,delaytime:int,[xoffset]:int,[yoffset]:int,[quantization]:int)->int
gif_save(gif:gif, filename:string)->int
gif_save_buffer(gif:gif)->buffer

// section 5.5

draw_set_font(font:font)->void
draw_get_font()->font
draw_set_halign(halign:horizontal_alignment)->void
draw_get_halign()->horizontal_alignment
fa_left#:horizontal_alignment
fa_center#:horizontal_alignment
fa_right#:horizontal_alignment
draw_set_valign(valign:vertical_alignment)->void
draw_get_valign()->vertical_alignment
fa_top#:vertical_alignment
fa_middle#:vertical_alignment
fa_bottom#:vertical_alignment
draw_text(x:number,y:number,string:string)->void
draw_text_ext(x:number,y:number,string:string,sep:number,w:number)->void
string_width(string:string)->number
string_height(string:string)->number
string_width_ext(string:string,sep:number,w:number)->number
string_height_ext(string:string,sep:number,w:number)->number
draw_text_transformed(x:number,y:number,string:string,xscale:number,yscale:number,angle:number)->void
draw_text_ext_transformed(x:number,y:number,string:string,sep:number,w:number,xscale:number,yscale:number,angle:number)->void
draw_text_colour(x:number,y:number,string:string,c1:int,c2:int,c3:int,c4:int,alpha:number)£->void
draw_text_ext_colour(x:number,y:number,string:string,sep:number,w:number,c1:int,c2:int,c3:int,c4:int,alpha:number)£->void
draw_text_transformed_colour(x:number,y:number,string:string,xscale:number,yscale:number,angle:number,c1:int,c2:int,c3:int,c4:int,alpha:number)£->void
draw_text_ext_transformed_colour(x:number,y:number,string:string,sep:number,w:number,xscale:number,yscale:number,angle:number,c1:int,c2:int,c3:int,c4:int,alpha:number)£->void
draw_text_color(x:number,y:number,string:string,c1:int,c2:int,c3:int,c4:int,alpha:number)$->void
draw_text_ext_color(x:number,y:number,string:string,sep:number,w:number,c1:int,c2:int,c3:int,c4:int,alpha:number)$->void
draw_text_transformed_color(x:number,y:number,string:string,xscale:number,yscale:number,angle:number,c1:int,c2:int,c3:int,c4:int,alpha:number)$->void
draw_text_ext_transformed_color(x:number,y:number,string:string,sep:number,w:number,xscale:number,yscale:number,angle:number,c1:int,c2:int,c3:int,c4:int,alpha:number)$->void

// section 5.6

draw_point_colour(x:number,y:number,col1:int)£->void
draw_line_colour(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int)£->void
draw_line_width_colour(x1:number,y1:number,x2:number,y2:number,w:number,col1:int,col2:int)£->void
draw_rectangle_colour(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int,col3:int,col4:int,outline:bool)£->void
draw_roundrect_colour(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int,outline:bool)£->void
draw_roundrect_colour_ext(x1:number,y1:number,x2:number,y2:number,radiusx:number,radiusy:number,col1:int,col2:int,outline:bool)£->void
draw_triangle_colour(x1:number,y1:number,x2:number,y2:number,x3:number,y3:number,col1:int,col2:int,col3:int,outline:bool)£->void
draw_circle_colour(x:number,y:number,r:number,col1:int,col2:int,outline:bool)£->void
draw_ellipse_colour(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int,outline:bool)£->void
draw_point_color(x:number,y:number,col1:int)$->void
draw_line_color(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int)$->void
draw_line_width_color(x1:number,y1:number,x2:number,y2:number,w:number,col1:int,col2:int)$->void
draw_rectangle_color(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int,col3:int,col4:int,outline:bool)$->void
draw_roundrect_color(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int,outline:bool)$->void
draw_roundrect_color_ext(x1:number,y1:number,x2:number,y2:number,radiusx:number,radiusy:number,col1:int,col2:int,outline:bool)$->void
draw_triangle_color(x1:number,y1:number,x2:number,y2:number,x3:number,y3:number,col1:int,col2:int,col3:int,outline:bool)$->void
draw_circle_color(x:number,y:number,r:number,col1:int,col2:int,outline:bool)$->void
draw_ellipse_color(x1:number,y1:number,x2:number,y2:number,col1:int,col2:int,outline:bool)$->void
pr_pointlist#:primitive_type
pr_linelist#:primitive_type
pr_linestrip#:primitive_type
pr_trianglelist#:primitive_type
pr_trianglestrip#:primitive_type
pr_trianglefan#:primitive_type
draw_primitive_begin(kind:primitive_type)->void
draw_vertex(x:number,y:number)->void
draw_vertex_colour(x:number,y:number,col:int,alpha:number)£->void
draw_vertex_color(x:number,y:number,col:int,alpha:number)$->void
draw_primitive_end()->void
sprite_get_uvs(spr:sprite,subimg:int)->Array<int>
font_get_uvs(font:font)->Array<font>
sprite_get_texture(spr:sprite,subimg:int)->texture
font_get_texture(font:font)->texture
texture_get_width(texid:texture)->int
texture_get_height(texid:texture)->int
texture_get_uvs(texid:texture)->Array<int>
draw_primitive_begin_texture(kind:primitive_type,texid:texture)->void
draw_vertex_texture(x:number,y:number,xtex:number,ytex:number)->void
draw_vertex_texture_colour(x:number,y:number,xtex:number,ytex:number,col:int,alpha:number)£->void
draw_vertex_texture_color(x:number,y:number,xtex:number,ytex:number,col:int,alpha:number)$->void
texture_global_scale(pow2integer:int)->void
bm_complex&:blendmode
bm_normal#:blendmode
bm_add#:blendmode
bm_max#:blendmode
bm_subtract#:blendmode
bm_zero#:blendmode_ext
bm_one#:blendmode_ext
bm_src_colour#£:blendmode_ext
bm_inv_src_colour#£:blendmode_ext
bm_src_color#$:blendmode_ext
bm_inv_src_color#$:blendmode_ext
bm_src_alpha#:blendmode_ext
bm_inv_src_alpha#:blendmode_ext
bm_dest_alpha#:blendmode_ext
bm_inv_dest_alpha#:blendmode_ext
bm_dest_colour#£:blendmode_ext
bm_inv_dest_colour#£:blendmode_ext
bm_dest_color#$:blendmode_ext
bm_inv_dest_color#$:blendmode_ext
bm_src_alpha_sat#:blendmode_ext

tf_point#:texture_mip_filter
tf_linear#:texture_mip_filter
tf_anisotropic#:texture_mip_filter

mip_off#:texture_mip_state
mip_on#:texture_mip_state
mip_markedonly#:texture_mip_state

audio_falloff_none#:audio_falloff_model
audio_falloff_inverse_distance#:audio_falloff_model
audio_falloff_inverse_distance_clamped#:audio_falloff_model
audio_falloff_linear_distance#:audio_falloff_model
audio_falloff_linear_distance_clamped#:audio_falloff_model
audio_falloff_exponent_distance#:audio_falloff_model
audio_falloff_exponent_distance_clamped#:audio_falloff_model

audio_old_system#&:any
audio_new_system#&:any

audio_mono#:audio_sound_channel
audio_stereo#:audio_sound_channel
audio_3d#:audio_sound_channel

// section 5.7_1

surface_create(w:int,h:int)->surface
surface_create_ext(name:string,w:int,h:int)->surface
surface_resize(id:surface,width:int,height:int)->void
surface_free(id:surface)->void
surface_exists(id:surface)->bool
surface_get_width(id:surface)->int
surface_get_height(id:surface)->int
surface_get_texture(id:surface)->texture
surface_set_target(id:surface)->void
surface_set_target_ext(index:int,id:surface)->bool
surface_get_target()->surface
surface_get_target_ext(index:int)->surface
surface_reset_target()->void
surface_depth_disable(disable:bool)->void
surface_get_depth_disable()->bool
draw_surface(id:surface,x:number,y:number)->void
draw_surface_stretched(id:surface,x:number,y:number,w:number,h:number)->void
draw_surface_tiled(id:surface,x:number,y:number)->void
draw_surface_part(id:surface,left:number,top:number,width:number,height:number,x:number,y:number)->void
draw_surface_ext(id:surface,x:number,y:number,xscale:number,yscale:number,rot:number,col:int,alpha:number)->void
draw_surface_stretched_ext(id:surface,x:number,y:number,w:number,h:number,col:int,alpha:number)->void
draw_surface_tiled_ext(id:surface,x:number,y:number,xscale:number,yscale:number,col:int,alpha:number)->void
draw_surface_part_ext(id:surface,left:number,top:number,width:number,height:number,x:number,y:number,xscale:number,yscale:number,col:int,alpha:number)->void
draw_surface_general(id:surface,left:number,top:number,width:number,height:number,x:number,y:number,xscale:number,yscale:number,rot:number,c1:int,c2:int,c3:int,c4:int,alpha:int)->void
surface_getpixel(id:surface,x:number,y:number)->int
surface_getpixel_ext(id:surface,x:number,y:number)->int
surface_save(id:surface,fname:string)->void
surface_save_part(id:surface,fname:string,x:number,y:number,w:int,h:int)->void
surface_copy(destination:surface,x:number,y:number,source:surface)->void
surface_copy_part(destination:surface,x:number,y:number,source:surface,xs:number,ys:number,ws:int,hs:int)->void

application_surface_draw_enable(on_off:bool)->void
application_get_position()->Array<int>
application_surface_enable(enable:bool)->void
application_surface_is_enabled()->bool


// section 5.8

display_get_width()->int
display_get_height()->int
display_get_orientation()->display_orientation
display_get_gui_width()->int
display_get_gui_height()->int

display_reset(aa_level:int, vsync:bool)->void
display_mouse_get_x()->number
display_mouse_get_y()->number
display_mouse_set(x:number,y:number)->void

display_set_ui_visibility(flags:int)->void

// section 5.9

window_set_fullscreen(full:bool)->void
window_get_fullscreen()->bool
window_set_caption(caption:string)->void
window_set_min_width(minwidth:int)->void
window_set_max_width(maxwidth:int)->void
window_set_min_height(minheight:int)->void
window_set_max_height(maxheight:int)->void
window_get_visible_rects(startx:int,starty:int,endx:int,endy:int)->Array<int>
window_get_caption()->string
window_set_cursor(cursor:window_cursor)->void
cr_default#:window_cursor
cr_none#:window_cursor
cr_arrow#:window_cursor
cr_cross#:window_cursor
cr_beam#:window_cursor
cr_size_nesw#:window_cursor
cr_size_ns#:window_cursor
cr_size_nwse#:window_cursor
cr_size_we#:window_cursor
cr_uparrow#:window_cursor
cr_hourglass#:window_cursor
cr_drag#:window_cursor
cr_appstart#:window_cursor
cr_handpoint#:window_cursor
cr_size_all#:window_cursor
window_get_cursor()->window_cursor
window_set_colour(colour:int)£->void
window_get_colour()£->int
window_set_color(color:int)$->void
window_get_color()$->int
window_set_position(x:int,y:int)->void
window_set_size(w:int,h:int)->void
window_set_rectangle(x:int,y:int,w:int,h:int)->void
window_center()->void
window_get_x()->int
window_get_y()->int
window_get_width()->int
window_get_height()->int
window_mouse_get_x()->int
window_mouse_get_y()->int
window_mouse_set(x:int,y:int)->void

// section 5.10

view_enabled:bool
view_current*:int
view_visible[0..7]:Array<int>
// view_xview[0..7]
// view_yview[0..7]
// view_wview[0..7]
// view_hview[0..7]
view_xport[0..7]:Array<int>
view_yport[0..7]:Array<int>
view_wport[0..7]:Array<int>
view_hport[0..7]:Array<int>
// view_angle[0..7]
// view_hborder[0..7]
// view_vborder[0..7]
// view_hspeed[0..7]
// view_vspeed[0..7]
// view_object[0..7]
view_surface_id[0..7]:Array<surface>
view_camera[0..7]:Array<camera>
window_view_mouse_get_x(id:int)->number
window_view_mouse_get_y(id:int)->number
window_views_mouse_get_x()->number
window_views_mouse_get_y()->number


//////////////
// Chapter 406
//////////////

// section 6.3

audio_listener_position(x:number,y:number,z:number)->void
audio_listener_velocity(vx:number,vy:number,vz:number)->void
audio_listener_orientation(lookat_x:number,lookat_y:number,lookat_z:number,up_x:number,up_y:number,up_z:number)->void
audio_emitter_position(emitterid:audio_emitter,x:number,y:number,z:number)->void
audio_emitter_create()->audio_emitter
audio_emitter_free(emitterid:audio_emitter)->void
audio_emitter_exists(emitterid:audio_emitter)->bool
audio_emitter_pitch(emitterid:audio_emitter,pitch:number)->void
audio_emitter_velocity(emitterid:audio_emitter,vx:number,vy:number,vz:number)->void
audio_emitter_falloff(emitterid:audio_emitter, falloff_ref_dist:number,falloff_max_dist:number,falloff_factor:number)->void
audio_emitter_gain(emitterid:audio_emitter,gain:number)->void
audio_play_sound(soundid:sound,priority:int,loops:bool)->sound_instance
audio_play_sound_on(emitterid:emitterid,soundid:sound,loops:bool,priority:int)->sound_instance
audio_play_sound_at(soundid:sound,x:number,y:number,z:number, falloff_ref_dist:number,falloff_max_dist:number,falloff_factor:number,loops:bool, priority:int)->sound_instance
audio_stop_sound(soundid:sound|sound_instance)->void
audio_resume_music()&->void
audio_music_is_playing()&->bool
audio_resume_sound(soundid:sound|sound_instance)->void
audio_pause_sound(soundid:sound|sound_instance)->void
audio_pause_music()&->void
audio_channel_num(numchannels:int)->void
audio_sound_length(soundid:sound|sound_instance)->number
audio_get_type(soundid:sound|sound_instance)->int
audio_falloff_set_model(falloffmode:audio_falloff_model)->void
audio_play_music(soundid:sound,loops:bool)&->void
audio_stop_music()&->void
audio_master_gain(gain:number)->void
audio_music_gain(value:number,time:number)&->void
audio_sound_gain(index:sound|sound_instance,level:number,time:number)->void
audio_sound_pitch(index:sound|sound_instance,pitch:number)->void
audio_stop_all()->void
audio_resume_all()->void
audio_pause_all()->void
audio_is_playing(soundid:sound|sound_instance)->bool
audio_is_paused(soundid:sound|sound_instance)->bool
audio_exists(soundid:sound|sound_instance)->bool
audio_system_is_available()->bool
audio_sound_is_playable(soundid:sound)->bool

//audio revision-getters
//audio_sound_set_track_position(soundid,time)
//audio_sound_get_track_position(soundid)
audio_emitter_get_gain(emitterid:audio_emitter)->number
audio_emitter_get_pitch(emitterid:audio_emitter)->number
audio_emitter_get_x(emitterid:audio_emitter)->number
audio_emitter_get_y(emitterid:audio_emitter)->number
audio_emitter_get_z(emitterid:audio_emitter)->number
audio_emitter_get_vx(emitterid:audio_emitter)->number
audio_emitter_get_vy(emitterid:audio_emitter)->number
audio_emitter_get_vz(emitterid:audio_emitter)->number
audio_listener_set_position(index:int, x:number,y:number,z:number)->void
audio_listener_set_velocity(index:int, vx:number,vy:number,vz:number)->void
audio_listener_set_orientation(index:int, lookat_x:number,lookat_y:number,lookat_z:number,up_x:number,up_y:number,up_z:number)->void
audio_listener_get_data(index:int)->ds_map<string, number>
audio_set_master_gain(listenerIndex:int, gain:number)->void
audio_get_master_gain(listenerIndex:int)->number
audio_sound_get_gain(index:sound|sound_instance)->number
audio_sound_get_pitch(index:sound|sound_instance)->number
audio_get_name(index:sound|sound_instance)->number
audio_sound_set_track_position(index:sound|sound_instance, time:number)->void
audio_sound_get_track_position(index:sound|sound_instance)->number
audio_create_stream(filename:string)!->sound
audio_destroy_stream(stream_sound_id:sound)!->void
audio_create_sync_group(looping:bool)->sound_sync_group
audio_destroy_sync_group(sync_group_id:sound_sync_group)->void
audio_play_in_sync_group(sync_group_id:sound_sync_group,soundid:sound)->sound_instance
audio_start_sync_group(sync_group_id:sound_sync_group)->void
audio_stop_sync_group(sync_group_id:sound_sync_group)->void
audio_pause_sync_group(sync_group_id:sound_sync_group)->void
audio_resume_sync_group(sync_group_id:sound_sync_group)->void
audio_sync_group_get_track_pos(sync_group_id:sound_sync_group)->number
audio_sync_group_debug(sync_group_id:sound_sync_group|int)->void
audio_sync_group_is_playing(sync_group_id:sound_sync_group)->bool
audio_debug(enable:bool)->void

audio_group_load( groupId:audio_group)->bool
audio_group_unload( groupId:audio_group)->bool
audio_group_is_loaded( groupId:audio_group )->bool
audio_group_load_progress( groupId:audio_group )->number
audio_group_name( groupId:audio_group )->string
audio_group_stop_all( groupId:audio_group)->void
audio_group_set_gain( groupId:audio_group, volume:number, time:number )->void
audio_create_buffer_sound( bufferId:buffer, format:buffer_type, rate:int, offset:int, length:int, channels:audio_sound_channel )!->sound
audio_free_buffer_sound( soundId:sound )!->void
audio_create_play_queue(bufferFormat:buffer_type, sampleRate:int, channels:audio_sound_channel)!->sound_play_queue
audio_free_play_queue(queueId:sound_play_queue)!->void
audio_queue_sound(queueId:sound_play_queue, buffer_id:buffer, offset:int, length:int)!->void

audio_get_recorder_count()->int
audio_get_recorder_info(recorder_num:int)->ds_map<string, any>
audio_start_recording(recorder_num:int)->buffer
audio_stop_recording(channel_index:int)->void

audio_sound_get_listener_mask(soundid:sound|sound_instance)->int
audio_emitter_get_listener_mask(emitterid:audio_emitter)->int
audio_get_listener_mask()->int
audio_sound_set_listener_mask(soundid:sound|sound_instance,mask:int)->void
audio_emitter_set_listener_mask(emitterid:emitterIndex,mask:int)->void
audio_set_listener_mask(mask:int)->void
audio_get_listener_count()->int
audio_get_listener_info(index:int)->ds_map<string, any>

audio_system()&->void

// section 11.4 / map
ds_map_values_to_array<K;V>(map:ds_map<K;V>, K[])->K[]
ds_map_keys_to_array<K;V>(map:ds_map<K;V>, V[])->V[]
ds_map_is_map<K;V>(map:ds_map<K;V>,key:K)->bool
ds_map_is_list<K;V>(map:ds_map<K;V>,key:K)->bool
