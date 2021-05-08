//////////////
// Chapter 401
//////////////

#region 2.0 - general

self#
other#
all#
noone#
global#
local&
undefined#:undefined

argument_relative&
argument_count:int

pointer_invalid#:pointer
pointer_null#:pointer

true#:bool
false#:bool
pi#:number

#endregion

#region 2.1

GM_build_date#:datetime
GM_version#:string

#endregion

#region 2.2

is_real(val:any)->bool
is_numeric(val:any)->bool
is_string(val:any)->bool
is_array(val:any)->bool
is_undefined(val:any)->bool
is_int32(val:any)->bool
is_int64(val:any)->bool
is_ptr(val:any)->bool
is_bool(val:any)->bool
// the following serve no purpose:
is_vec3(val:any)&->bool
is_vec4(val:any)&->bool
is_matrix(val:any)&->bool

typeof(val:any)->string

variable_global_exists(name:string)->bool
variable_global_get(name:string)->any
variable_global_set(name:string,val:any)->void
variable_instance_exists<T:instance>(id:T,name:string)->bool
variable_instance_get<T:instance>(id:T,name:string)->any
variable_instance_set<T:instance>(id:T,name:string,val:any)->void

array_equals<T0, T1>(var1:T0[],var2:T1[])->bool
array_create<T>(size:int, ?value:T)->array<T> // TODO
array_copy<T>(dest:T[],dest_index:int,src:T[],src_index:int,length:int)->void
array_get<T>(variable:T[],index:int)->any
array_set<T>(variable:T[],index:int,val:any)->void

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

#endregion

#region 2.3

real(val:string)->number
bool(val:number)->bool
string(val:any)->string
int64(val:number)->int
ptr(val:number|string)->pointer
string_format(val:number,total:int,dec:int)->string
chr(val:int)->string
ansi_char(val:int)->string
ord(char:string)->int

string_length(str:string)->int
string_byte_length(str:string)->int
string_pos(substr:string,str:string)->int
string_pos_ext(substr:string,str:string,startpos:int)->int
string_last_pos(substr:string,str:string)->int
string_last_pos_ext(substr:string,str:string,startpos:int)->int
string_copy(str:string,index:int,count:int)->string
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

#endregion

#region 2.4

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

#endregion

//////////////
// Chapter 403
//////////////

#region 3.1

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

motion_set(dir:number,speed:number)->void
motion_add(dir:number,speed:number)->void
place_free(x:number,y:number)->bool
place_empty<T:object|instance>(x:number,y:number,obj:T)->bool
place_meeting<T:object|instance>(x:number,y:number,obj:T)->bool
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
distance_to_object<T:object|instance>(obj:T)->number
position_empty(x:number,y:number)->bool
position_meeting<T:object|instance>(x:number,y:number,obj:T)->bool

#endregion

#region 3.2

path_start(path:path,speed:number,endaction:path_endaction,absolute:bool)->void
path_end()->void
path_index*@:path
path_position@:number
path_positionprevious@:number
path_speed@:number
path_scale@:number
path_orientation@:number
path_endaction@:path_endaction

path_action_stop#:path_endaction
path_action_restart#:path_endaction
path_action_continue#:path_endaction
path_action_reverse#:path_endaction

#endregion

#region 3.3

mp_linear_step(x:number,y:number,speed:number,checkall:bool)->bool
mp_potential_step(x:number,y:number,speed:number,checkall:bool)->bool
mp_linear_step_object<T:object|instance>(x:number,y:number,speed:number,obj:T)->bool
mp_potential_step_object<T:object|instance>(x:number,y:number,speed:number,obj:T)->bool
mp_potential_settings(maxrot:number,rotstep:number,ahead:int,onspot:bool)->void
mp_linear_path(path:path,xg:number,yg:number,stepsize:number,checkall:bool)->bool
mp_potential_path(path:path,xg:number,yg:number,stepsize:number,factor:int,checkall:bool)->bool
mp_linear_path_object<T:object|instance>(path:path,xg:number,yg:number,stepsize:number,obj:T)->bool
mp_potential_path_object<T:object|instance>(path:path,xg:number,yg:number,stepsize:number,factor:int,obj:T)->bool
mp_grid_create(left:number,top:number,hcells:int,vcells:int,cellwidth:number,cellheight:number)->mp_grid
mp_grid_destroy(id:mp_grid)->void
mp_grid_clear_all(id:mp_grid)->void
mp_grid_clear_cell(id:mp_grid,h:int,v:int)->void
mp_grid_clear_rectangle(id:mp_grid,left:int,top:int,right:int,bottom:int)->void
mp_grid_add_cell(id:mp_grid,h:int,v:int)->void
mp_grid_get_cell(id:mp_grid,h:int,v:int)->int
mp_grid_add_rectangle(id:mp_grid,left:int,top:int,right:int,bottom:int)->void
mp_grid_add_instances<T:object|instance>(id:mp_grid,obj:T,prec:bool)->void
mp_grid_path(id:mp_grid,path:path,xstart:number,ystart:number,xgoal:number,ygoal:number,allowdiag:bool)->bool
mp_grid_draw(id:mp_grid)->void
mp_grid_to_ds_grid(src:mp_grid,dest:ds_grid<number>)->bool

#endregion

#region 3.4

collision_point<T:object|instance>(x:number,y:number,obj:T,prec:bool,notme:bool)->T
collision_rectangle<T:object|instance>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool)->T
collision_circle<T:object|instance>(x1:number,y1:number,radius:number,obj:T,prec:bool,notme:bool)->T
collision_ellipse<T:object|instance>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool)->T
collision_line<T:object|instance>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool)->T

point_in_rectangle(px:number,py:number,x1:number,y1:number,x2:number,y2:number)->bool
point_in_triangle(px:number,py:number,x1:number,y1:number,x2:number,y2:number,x3:number,y3:number)->bool
point_in_circle(px:number,py:number,cx:number,cy:number,rad:number)->bool
rectangle_in_rectangle(sx1:number,sy1:number,sx2:number,sy2:number,dx1:number,dy1:number,dx2:number,dy2:number)->bool
rectangle_in_triangle(sx1:number,sy1:number,sx2:number,sy2:number,x1:number,y1:number,x2:number,y2:number,x3:number,y3:number)->bool
rectangle_in_circle(sx1:number,sy1:number,sx2:number,sy2:number,cx:number,cy:number,rad:number)->bool

#endregion

#region 3.5

object_index*@ // TODO
id*@ // TODO
solid@:bool
persistent@:bool
mask_index@:sprite
instance_count*@:int
instance_id*@ // TODO
instance_find<T:object>(obj:T,n:int)->T
instance_exists<T:object|instance>(obj:T)->bool
instance_number<T:object>(obj:T)->bool
instance_position<T:object|instance>(x:number,y:number,obj:T)->T
instance_nearest<T:object|instance>(x:number,y:number,obj:T)->T
instance_furthest<T:object|instance>(x:number,y:number,obj:T)->T
instance_place<T:object|instance>(x:number,y:number,obj:T)->T
instance_create_depth<T:object>(x:number,y:number,depth:number,obj:T)->T
instance_create_layer<T:object>(x:number,y:number,layer_id_or_name:layer|string,obj:T)->T
instance_copy(performevent) // TODO... good luck with this one
instance_change<T:object|instance>(obj:T,performevents:bool)->void
instance_destroy<T:object|instance>(?id*:T,?execute_event_flag*:bool)->void
position_destroy(x:number,y:number)->void
position_change<T:object>(x:number,y:number,obj:T,performevents:bool)->void
instance_id_get(index:int)->any // where any:instance

#endregion

#region 3.6

instance_deactivate_all(notme:bool)->void
instance_deactivate_object<T:object|instance>(obj:T)->void
instance_deactivate_region(left:number,top:number,width:number,height:number,inside:bool,notme:bool)->void
instance_activate_all()->void
instance_activate_object<T:object|instance>(obj:T)->void
instance_activate_region(left:number,top:number,width:number,height:number,inside:bool)->void

#endregion

#region 3.7

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

#endregion

#region 3.8

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

#endregion

#region 3.9

score:number
lives:number
health:number

#endregion

#region 3.10

event_perform<T:object>(type:event_type,numb:int|event_number|T)->void
event_user(numb:int)->void
event_perform_object<T0:object, T1:object>(obj:T0,type:event_type,numb:int|event_number|T1)->void
event_inherited()->void
event_type*:any
event_number*:int|event_number
event_object*:object
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

#endregion

#region 3.11

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
debug_get_callstack()->string[]
alarm_get(index:int)->int
alarm_set(index:int,count:int)->void

#endregion

//////////////
// Chapter 404
//////////////

#region 4.1

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

#endregion

#region 4.2

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

#endregion

//////////////
// Chapter 405
//////////////

#region 5.1

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

#endregion

#region 5.2

background_colour£:int
background_showcolour£:bool
background_color$:int
background_showcolor$:bool

#endregion

#region 5.3

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

#endregion

#region 5.4

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

#endregion

#region 5.5

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

#endregion

#region 5.6

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
sprite_get_uvs(spr:sprite,subimg:int)->int[]
font_get_uvs(font:font)->font[]
sprite_get_texture(spr:sprite,subimg:int)->texture
font_get_texture(font:font)->texture
texture_get_width(texid:texture)->int
texture_get_height(texid:texture)->int
texture_get_uvs(texid:texture)->int[]
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

#endregion

#region 5.7_1

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
application_get_position()->int[]
application_surface_enable(enable:bool)->void
application_surface_is_enabled()->bool


#endregion

#region 5.8

display_get_width()->int
display_get_height()->int

display_get_orientation()->display_orientation
display_landscape#:display_orientation
display_landscape_flipped#:display_orientation
display_portrait#:display_orientation
display_portrait_flipped#:display_orientation

display_get_gui_width()->int
display_get_gui_height()->int

display_reset(aa_level:int, vsync:bool)->void
display_mouse_get_x()->number
display_mouse_get_y()->number
display_mouse_set(x:number,y:number)->void

display_set_ui_visibility(flags:int)->void

#endregion

#region 5.9

window_set_fullscreen(full:bool)->void
window_get_fullscreen()->bool
window_set_caption(caption:string)->void
window_set_min_width(minwidth:int)->void
window_set_max_width(maxwidth:int)->void
window_set_min_height(minheight:int)->void
window_set_max_height(maxheight:int)->void
window_get_visible_rects(startx:int,starty:int,endx:int,endy:int)->int[]
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

#endregion

#region 5.10

view_enabled:bool
view_current*:int
view_visible[0..7]:int[]
// view_xview[0..7]
// view_yview[0..7]
// view_wview[0..7]
// view_hview[0..7]
view_xport[0..7]:int[]
view_yport[0..7]:int[]
view_wport[0..7]:int[]
view_hport[0..7]:int[]
// view_angle[0..7]
// view_hborder[0..7]
// view_vborder[0..7]
// view_hspeed[0..7]
// view_vspeed[0..7]
// view_object[0..7]
view_surface_id[0..7]:surface[]
window_view_mouse_get_x(id:int)->number
window_view_mouse_get_y(id:int)->number
window_views_mouse_get_x()->number
window_views_mouse_get_y()->number

#endregion

//////////////
// Chapter 406
//////////////

#region 6.3

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
audio_play_sound_on(emitterid:audio_emitter,soundid:sound,loops:bool,priority:int)->sound_instance
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
audio_listener_get_data(index:int)->ds_map<string,number>
audio_set_master_gain(listenerIndex:int, gain:number)->void
audio_get_master_gain(listenerIndex:int)->number
audio_sound_get_gain(index:sound|sound_instance)->number
audio_sound_get_pitch(index:sound|sound_instance)->number
audio_get_name(index:sound|sound_instance)->string
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
audio_get_recorder_info(recorder_num:int)->ds_map<string,any>
audio_start_recording(recorder_num:int)->buffer
audio_stop_recording(channel_index:int)->void

audio_sound_get_listener_mask(soundid:sound|sound_instance)->int
audio_emitter_get_listener_mask(emitterid:audio_emitter)->int
audio_get_listener_mask()->int
audio_sound_set_listener_mask(soundid:sound|sound_instance,mask:int)->void
audio_emitter_set_listener_mask(emitterid:audio_emitter,mask:int)->void
audio_set_listener_mask(mask:int)->void
audio_get_listener_count()->int
audio_get_listener_info(index:int)->ds_map<string,any>

#endregion

//////////////
// Chapter 407
//////////////

#region 7.2

show_message(str:string)->void
show_message_async(str:string)->void
clickable_add(x:number,y:number,spritetpe:html_clickable_tpe,URL:string,target:string,params:string)->html_clickable
clickable_add_ext(x:number,y:number,spritetpe:html_clickable_tpe,URL:string,target:string,params:string,scale:number,alpha:number)->html_clickable
clickable_change(buttonid:html_clickable,spritetpe:html_clickable_tpe,x:number,y:number)->void
clickable_change_ext(buttonid:html_clickable,spritetpe:html_clickable_tpe,x:number,y:number,scale:number,alpha:number)->void
clickable_delete(buttonid:html_clickable)->void
clickable_exists(index:html_clickable)->bool
clickable_set_style(buttonid:html_clickable,map:ds_map<string; string>)->bool

show_question(str:string)->bool
show_question_async(str:string)->int
get_integer(str:string,def:number)->number
get_string(str:string,def:string)->string
get_integer_async(str:string,def:number)->int
get_string_async(str:string,def:string)->int
get_login_async(username:string,password:string)->int
get_open_filename(filter:string,fname:string)->string
get_save_filename(filter:string,fname:string)->string
get_open_filename_ext(filter:string,fname:string,dir:string,title:string)->string
get_save_filename_ext(filter:string,fname:string,dir:string,title:string)->string
show_error(str:string,abort:bool)->void

#endregion

#region 7.3

highscore_clear()->void
highscore_add(str:string,numb:number)->void
highscore_value(place:int)->number
highscore_name(place:int)->string
draw_highscore(x1:number,y1:number,x2:number,y2:number)->void

#endregion

//////////////
// Chapter 408
//////////////

#region 8.1

sprite_exists(ind:sprite)->bool
sprite_get_name(ind:sprite)->string
sprite_get_number(ind:sprite)->int
sprite_get_width(ind:sprite)->int
sprite_get_height(ind:sprite)->int
sprite_get_xoffset(ind:sprite)->number
sprite_get_yoffset(ind:sprite)->number
sprite_get_bbox_mode(ind:sprite)->bbox_mode
sprite_get_bbox_left(ind:sprite)->number
sprite_get_bbox_right(ind:sprite)->number
sprite_get_bbox_top(ind:sprite)->number
sprite_get_bbox_bottom(ind:sprite)->number

sprite_set_bbox_mode(ind:sprite,mode:bbox_mode)->void
sprite_set_bbox(ind:sprite,left:number,top:number,right:number,bottom:number)->void

sprite_save(ind:sprite,subimg:int,fname:string)->void
sprite_save_strip(ind:sprite,fname:string)->void

sprite_set_cache_size(ind:sprite, max:int)->void
sprite_set_cache_size_ext(ind:sprite, image:int, max:int)->void
sprite_get_tpe(index,subindex)->html_clickable_tpe

sprite_prefetch(ind:sprite)->int
sprite_prefetch_multi(indarray:sprite[])->int

sprite_flush(ind:sprite)->int
sprite_flush_multi(indarray:sprite[])->int

#endregion

#region 8.4

font_exists(ind:font)->bool
font_get_name(ind:font)->string
font_get_fontname(ind:font)->string
font_get_bold(ind:font)->bool
font_get_italic(ind:font)->bool
font_get_first(ind:font)->int
font_get_last(ind:font)->int
font_get_size(ind:font)->int
font_set_cache_size(font:font,max:int)->void

#endregion

#region 8.5

path_exists(ind:path)->bool
path_get_name(ind:path)->string
path_get_length(ind:path)->number
path_get_kind(ind:path)->bool
path_get_closed(ind:path)->bool
path_get_precision(ind:path)->int
path_get_number(ind:path)->int
path_get_point_x(ind:path,n:int)->number
path_get_point_y(ind:path,n:int)->number
path_get_point_speed(ind:path,n:int)->number
path_get_x(ind:path,pos:number)->number
path_get_y(ind:path,pos:number)->number
path_get_speed(ind:path,pos:number)->number

#endregion

#region 8.6

script_exists(ind:script)->bool
script_get_name(ind:script)->string

#endregion

#region 8.7

timeline_add()!->timeline
timeline_delete(ind:timeline)!->void
timeline_clear(ind:timeline)->void
timeline_exists(ind:timeline)->bool
timeline_get_name(ind:timeline)->string
timeline_moment_clear(ind:timeline,step:int)->void
timeline_moment_add_script(ind:timeline,step:int,script:script)->void
timeline_size(ind:timeline)->int
timeline_max_moment(ind:timeline)->int

#endregion

#region 8.8

object_exists<T:object>(ind:T)->bool
object_get_name<T:object>(ind:T)->string
object_get_sprite<T:object>(ind:T)->sprite
object_get_solid<T:object>(ind:T)->bool
object_get_visible<T:object>(ind:T)->bool
object_get_persistent<T:object>(ind:T)->bool
object_get_mask<T:object>(ind:T)->sprite
object_get_parent<T:object, any:object>(ind:T)->any
object_get_physics<T:object>(ind:T)->bool
object_is_ancestor<T0:object, T1:object>(ind_child:T0,ind_parent:T1)->bool

#endregion

#region 8.9

room_exists(ind:room)->bool
room_get_name(ind:room)->string

#endregion

#region 9.1

sprite_set_offset(ind:sprite,xoff:number,yoff:number)->void
sprite_duplicate(ind:sprite)!->sprite
sprite_assign(ind:sprite,source:sprite)->void
sprite_merge(ind1:sprite,ind2:sprite)->void
sprite_add(fname:string,imgnumb:number,removeback:bool,smooth:bool,xorig:number,yorig:number)!->sprite
sprite_replace(ind:sprite,fname:string,imgnumb:number,removeback:bool,smooth:bool,xorig:number,yorig:number)!->void
sprite_create_from_surface(id:surface,x:int,y:int,w:int,h:int,removeback:bool,smooth:bool,xorig:number,yorig:number)!->sprite
sprite_add_from_surface(sprite:sprite,surface:surface,x:int,y:int,w:int,h:int,removeback:bool,smooth:bool)!->sprite
sprite_delete(ind:sprite)!->void
sprite_set_alpha_from_sprite(ind:sprite,spr:sprite)->void
sprite_collision_mask(ind:sprite,sepmasks:bool,bboxmode:int,bbleft:number,bbtop:number,bbright:number,bbbottom:number,kind:bbox_kind,tolerance:int)->void

#endregion

#region 9.4

font_add_enable_aa(enable:bool)->void
font_add_get_enable_aa()->bool
font_add(name:string,size:number,bold:bool,italic:bool,first:int,last:int)!->font
font_add_sprite(spr:sprite,first:int,prop:bool,sep:number)!->font
font_add_sprite_ext(spr:sprite,mapstring:string,prop:bool,sep:number)!->font
font_replace(ind:font,name:string,size:number,bold:bool,italic:bool,first:int,last:int)!->void
font_replace_sprite(ind:font,spr:sprite,first:int,prop:bool,sep:number)!->void
font_replace_sprite_ext(font:font,spr:sprite,mapstring:string,prop:bool,sep:number)!->void
font_delete(ind:font)!->void

#endregion

#region 9.5

path_set_kind(ind:path,kind:bool)->void
path_set_closed(ind:path,closed:bool)->void
path_set_precision(ind:path,prec:int)->void
path_add()!->path
path_assign(target:path,source:path)->void
path_duplicate(ind:path)!->path
path_append(ind:path,path:path)->void
path_delete(ind:path)->void
path_add_point(ind:path,x:number,y:number,speed:number)->void
path_insert_point(ind:path,n:int,x:number,y:number,speed:number)->void
path_change_point(ind:path,n:int,x:number,y:number,speed:number)->void
path_delete_point(ind:path,n:int)!->void
path_clear_points(ind:path)->void
path_reverse(ind:path)->void
path_mirror(ind:path)->void
path_flip(ind:path)->void
path_rotate(ind:path,angle:number)->void
path_rescale(ind:path,xscale:number,yscale:number)->void
path_shift(ind:path,xshift:number,yshift:number)->void

#endregion

#region 9.6

script_execute(ind:script,...values:any)->any

#endregion

#region 9.8

object_set_sprite<T:object>(ind:T,spr:sprite)->void
object_set_solid<T:object>(ind:T,solid:bool)->void
object_set_visible<T:object>(ind:T,vis:bool)->void
object_set_persistent<T:object>(ind:T,pers:bool)->void
object_set_mask<T:object>(ind:T,spr:sprite)->void

#endregion

#region 9.9

room_set_width(ind:room,w:number)->void
room_set_height(ind:room,h:number)->void
room_set_persistent(ind:room,pers:bool)->void
room_set_background_colour(ind:room,col:int,show:bool)£&->void
room_set_background_color(ind:room,col:int,show:bool)$&->void
// room_set_view(ind,vind,vis,xview,yview,wview,hview,xport,yport,wport,hport,hborder,vborder,hspeed,vspeed,obj)
room_set_viewport(ind:room,vind:int,vis:bool,xport:number,yport:number,wport:number,hport:number)->void
room_get_viewport(ind:room,vind:int)->any[]
room_set_view_enabled(ind:room,val:bool)->void
room_add()!->room
room_duplicate(ind:room)!->room
room_assign(ind:room,source:room)->void
room_instance_add<T:object>(ind:room,x:number,y:number,obj:T)->void
room_instance_clear(ind:room)->void

//asset_get_index<T:asset>(name:string)->T // not supported yet
asset_get_index(name:string)->any
asset_get_type(name:string)->asset_type

asset_object#:asset_type
asset_unknown#:asset_type
asset_sprite#:asset_type
asset_sound#:asset_type
asset_room#:asset_type
asset_path#:asset_type
asset_script#:asset_type
asset_font#:asset_type
asset_timeline#:asset_type
asset_shader#:asset_type

#endregion

#region 10.1

file_text_open_from_string(content:string)->file_handle
file_text_open_read(fname:string)->file_handle
file_text_open_write(fname:string)->file_handle
file_text_open_append(fname:string)->file_handle
file_text_close(file:file_handle)->void
file_text_write_string(file:file_handle,str:string)->void
file_text_write_real(file:file_handle,val:number)->void
file_text_writeln(file:file_handle)->void
file_text_read_string(file:file_handle)->string
file_text_read_real(file:file_handle)->number
file_text_readln(file:file_handle)->string
file_text_eof(file:file_handle)->bool
file_text_eoln(file:file_handle)->bool
file_exists(fname:string)->bool
file_delete(fname:string)->bool
file_rename(oldname:string,newname:string)->bool
file_copy(fname:string,newname:string)->bool

directory_exists(dname:string)->bool
directory_create(dname:string)->void
directory_destroy(dname:string)->void

file_find_first(mask:string,attr:int|file_attribute)->string
file_find_next()->string
file_find_close()->void

file_attributes(fname:string,attr:int|file_attribute)->bool
fa_readonly#:file_attribute
fa_hidden#:file_attribute
fa_sysfile#:file_attribute
fa_volumeid#:file_attribute
fa_directory#:file_attribute
fa_archive#:file_attribute

filename_name(fname:string)->string
filename_path(fname:string)->string
filename_dir(fname:string)->string
filename_drive(fname:string)->string
filename_ext(fname:string)->string
filename_change_ext(fname:string,newext:string)->string

file_bin_open(fname:string,mode:int)->binary_file_handle
file_bin_rewrite(file:binary_file_handle)->void
file_bin_close(file:binary_file_handle)->void
file_bin_position(file:binary_file_handle)->int
file_bin_size(file:binary_file_handle)->int
file_bin_seek(file:binary_file_handle,pos:int)->void
file_bin_write_byte(file:binary_file_handle,byte:int)->void
file_bin_read_byte(file:binary_file_handle)->int

parameter_count()->int
parameter_string(n:int)->string

environment_get_variable(name:string)->string

game_id*:int
game_display_name*:string
game_project_name*:string
game_save_id*:int
working_directory*:string
temp_directory*:string
program_directory*:string

#endregion

#region 10.3

ini_open_from_string(content:string)->void
ini_open(fname:string)->void
ini_close()->string
ini_read_string(section:string,key:string,default:string)->string
ini_read_real(section:string,key:string,default:number)->number
ini_write_string(section:string,key:string,str:string)->void
ini_write_real(section:string,key:string,value:number)->void
ini_key_exists(section:string,key:string)->bool
ini_section_exists(section:string)->bool
ini_key_delete(section:string,key:string)->void
ini_section_delete(section:string)->void

#endregion

//////////////
// Chapter 411
//////////////

#region 11.0 - ds general

ds_set_precision(prec:number)
ds_exists(id, type:ds_type)->bool

ds_type_map#:ds_type
ds_type_list#:ds_type
ds_type_stack#:ds_type
ds_type_queue#:ds_type
ds_type_grid#:ds_type
ds_type_priority#:ds_type

#endregion

#region 11.1 - stack

ds_stack_create()->ds_stack
ds_stack_destroy<T>(id:ds_stack<T>)->void
ds_stack_clear<T>(id:ds_stack<T>)->void
ds_stack_copy<T>(id:ds_stack<T>,source:ds_stack<T>)->void
ds_stack_size<T>(id:ds_stack<T>)->int
ds_stack_empty<T>(id:ds_stack<T>)->bool
ds_stack_push<T>(id:ds_stack<T>,...values:T)->void
ds_stack_pop<T>(id:ds_stack<T>)->T
ds_stack_top<T>(id:ds_stack<T>)->T
ds_stack_write<T>(id:ds_stack<T>)->string
ds_stack_read<T>(id:ds_stack<T>,str, ?legacy:bool)->void

#endregion

#region 11.2 - queue

ds_queue_create()->ds_queue
ds_queue_destroy<T>(id:ds_queue<T>)->void
ds_queue_clear<T>(id:ds_queue<T>)->void
ds_queue_copy<T>(id:ds_queue<T>,source:ds_queue<T>)->void
ds_queue_size<T>(id:ds_queue<T>)->int
ds_queue_empty<T>(id:ds_queue<T>)->bool
ds_queue_enqueue<T>(id:ds_queue<T>,...values:T)->void
ds_queue_dequeue<T>(id:ds_queue<T>)->T
ds_queue_head<T>(id:ds_queue<T>)->T
ds_queue_tail<T>(id:ds_queue<T>)->T
ds_queue_write<T>(id:ds_queue<T>)->string
ds_queue_read<T>(id:ds_queue<T>,str:string,?legacy:bool)->void

#endregion

#region 11.3 - list

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
ds_list_mark_as_list<T>(list:ds_list<T>,pos:int)
ds_list_mark_as_map<T>(list:ds_list<T>,pos:int)
ds_list_sort<T>(list:ds_list<T>,ascending:bool)
ds_list_shuffle<T>(list:ds_list<T>)
ds_list_write<T>(list:ds_list<T>)->string
ds_list_read<T>(list:ds_list<T>, str:string, ?legacy:bool)
ds_list_set<T>(list:ds_list<T>,pos:int,value:T)

#endregion

#region 11.4 - map

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

#endregion

#region 11.5 - priority

ds_priority_create()->ds_priority
ds_priority_destroy<T>(id:ds_priority<T>)->void
ds_priority_clear<T>(id:ds_priority<T>)->void
ds_priority_copy<T>(id:ds_priority<T>,source:ds_priority<T>)->void
ds_priority_size<T>(id:ds_priority<T>)->int
ds_priority_empty<T>(id:ds_priority<T>)->bool
ds_priority_add<T>(id:ds_priority<T>,value:T,priority:number)->void
ds_priority_change_priority<T>(id:ds_priority<T>,value:T,priority:number)->void
ds_priority_find_priority<T>(id:ds_priority<T>,value:T)->number
ds_priority_delete_value<T>(id:ds_priority<T>,value:T)->void
ds_priority_delete_min<T>(id:ds_priority<T>)->T
ds_priority_find_min<T>(id:ds_priority<T>)->T
ds_priority_delete_max<T>(id:ds_priority<T>)->T
ds_priority_find_max<T>(id:ds_priority<T>)->T
ds_priority_write<T>(id:ds_priority<T>)->string
ds_priority_read<T>(id:ds_priority<T>,str:string,?legacy:bool)->void

#endregion

#region 11.6 - grid

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

#endregion

//////////////
// Chapter 412
//////////////

#region 12.1a

effect_create_below(kind:effect_kind,x:number,y:number,size:int,col:int)->void
effect_create_above(kind:effect_kind,x:number,y:number,size:int,col:int)->void
effect_clear()
ef_explosion#:effect_kind
ef_ring#:effect_kind
ef_ellipse#:effect_kind
ef_firework#:effect_kind
ef_smoke#:effect_kind
ef_smokeup#:effect_kind
ef_star#:effect_kind
ef_spark#:effect_kind
ef_flare#:effect_kind
ef_cloud#:effect_kind
ef_rain#:effect_kind
ef_snow#:effect_kind

#endregion

#region 12.1

part_type_create()->particle
part_type_destroy(ind:particle)->void
part_type_exists(ind:particle)->bool
part_type_clear(ind:particle)->void
part_type_shape(ind:particle,shape:particle_shape)->void
part_type_sprite(ind:particle,sprite:sprite,animat:bool,stretch:bool,random:bool)->void
part_type_size(ind:particle,size_min:number,size_max:number,size_incr:number,size_wiggle:number)->void
part_type_scale(ind:particle,xscale:number,yscale:number)->void
part_type_orientation(ind:particle,ang_min:number,ang_max:number,ang_incr:number,ang_wiggle:number,ang_relative:bool)->void
part_type_life(ind:particle,life_min:number,life_max:number)->void
part_type_step(ind:particle,step_number:int,step_type:particle)->void
part_type_death(ind:particle,death_number:int,death_type:particle)->void
part_type_speed(ind:particle,speed_min:number,speed_max:number,speed_incr:number,speed_wiggle:number)->void
part_type_direction(ind:particle,dir_min:number,dir_max:number,dir_incr:number,dir_wiggle:number)->void
part_type_gravity(ind:particle,grav_amount:number,grav_dir:number)->void
part_type_colour1(ind:particle,colour1:int)£->void
part_type_colour2(ind:particle,colour1:int,colour2:int)£->void
part_type_colour3(ind:particle,colour1:int,colour2:int,colour3:int)£->void
part_type_colour_mix(ind:particle,colour1:int,colour2:int)£->void
part_type_colour_rgb(ind:particle,rmin:int,rmax:int,gmin:int,gmax:int,bmin:int,bmax:int)£->void
part_type_colour_hsv(ind:particle,hmin:number,hmax:number,smin:number,smax:number,vmin:number,vmax:number)£->void
part_type_color1(ind:particle,color1:int)$->void
part_type_color2(ind:particle,color1:int,color2:int)$->void
part_type_color3(ind:particle,color1:int,color2:int,color3:int)$->void
part_type_color_mix(ind:particle,color1:int,color2:int)$->void
part_type_color_rgb(ind:particle,rmin:int,rmax:int,gmin:int,gmax:int,bmin:int,bmax:int)$->void
part_type_color_hsv(ind:particle,hmin:number,hmax:number,smin:number,smax:number,vmin:number,vmax:number)$->void
part_type_alpha1(ind:particle,alpha1:number)->void
part_type_alpha2(ind:particle,alpha1:number,alpha2:number)->void
part_type_alpha3(ind:particle,alpha1:number,alpha2:number,alpha3:number)->void
part_type_blend(ind:particle,additive:bool)->void
pt_shape_pixel#:particle_shape
pt_shape_disk#:particle_shape
pt_shape_square#:particle_shape
pt_shape_line#:particle_shape
pt_shape_star#:particle_shape
pt_shape_circle#:particle_shape
pt_shape_ring#:particle_shape
pt_shape_sphere#:particle_shape
pt_shape_flare#:particle_shape
pt_shape_spark#:particle_shape
pt_shape_explosion#:particle_shape
pt_shape_cloud#:particle_shape
pt_shape_smoke#:particle_shape
pt_shape_snow#:particle_shape

#endregion

#region 12.2

part_system_create()->particle_system
part_system_create_layer(layer:layer|string,persistent:bool)->particle_system
part_system_destroy(ind:particle_system)->void
part_system_exists(ind:particle_system)->bool
part_system_clear(ind:particle_system)->void
part_system_draw_order(ind:particle_system,oldtonew:bool)->void
part_system_depth(ind:particle_system,depth:number)->void
part_system_position(ind:particle_system,x:number,y:number)->void
part_system_automatic_update(ind:particle_system,automatic:bool)->void
part_system_automatic_draw(ind:particle_system,draw:bool)->void
part_system_update(ind:particle_system)->void
part_system_drawit(ind:particle_system)->void
part_system_get_layer(ind:particle_system)->layer
part_system_layer(ind:particle_system,layer:layer|string)->void

part_particles_create(ind:particle_system,x:number,y:number,parttype:particle,number:int)->void
part_particles_create_colour(ind:particle_system,x:number,y:number,parttype:particle,colour:int,number:int)£->void
part_particles_create_color(ind:particle_system,x:number,y:number,parttype:particle,color:int,number:int)$->void
part_particles_clear(ind:particle_system)->void
part_particles_count(ind:particle_system)->int

#endregion

#region 12.3

part_emitter_create(ps:particle_system)->particle_emitter
part_emitter_destroy(ps:particle_system,emitter:particle_emitter)->void
part_emitter_destroy_all(ps:particle_system)->void
part_emitter_exists(ps:particle_system,ind:particle_emitter)->bool
part_emitter_clear(ps:particle_system,ind:particle_emitter)->void
part_emitter_region(ps:particle_system,ind:particle_emitter,xmin:number,xmax:number,ymin:number,ymax:number,shape:particle_region_shape,distribution:particle_distribution)->void
part_emitter_burst(ps:particle_system,ind:particle_emitter,parttype:particle,number:int)->void
part_emitter_stream(ps:particle_system,ind:particle_emitter,parttype:particle,number:int)->void
ps_distr_linear#:particle_distribution
ps_distr_gaussian#:particle_distribution
ps_distr_invgaussian#:particle_distribution
ps_shape_rectangle#:particle_region_shape
ps_shape_ellipse#:particle_region_shape
ps_shape_diamond#:particle_region_shape
ps_shape_line#:particle_region_shape

#endregion

//////////////
// Chapter 414
//////////////

#region 14

external_define(dll_path:string, func_name:string, calltype:external_call_type, restype:external_value_type, argnumb:number, ...argtypes:external_value_type)!->external_function
external_call(func:external_function, ...arguments)!
external_free(dllname:string)!
dll_cdecl#:external_call_type
dll_stdcall#:external_call_type
ty_real#:external_value_type
ty_string#:external_value_type

window_handle()->pointer
window_device()->pointer

#endregion

//////////////
// Chapter 415
//////////////

#region 15

matrix_view#:matrix_type
matrix_projection#:matrix_type
matrix_world#:matrix_type
matrix_get(type:matrix_type)->number[]
matrix_set(type:matrix_type,matrix:number[])->void
matrix_build(x:number,y:number,z:number,xrotation:number,yrotation:number,zrotation:number,xscale:number,yscale:number,zscale:number)->number[]
matrix_multiply(matrix:number[],matrix:number[])->number[]

#endregion

#region 15.a

os_type*:os_type
os_win32#&:os_type
os_windows#:os_type
os_macosx#:os_type
os_ios#:os_type
os_android#:os_type
os_linux#:os_type
os_unknown#:os_type
os_winphone#:os_type
os_win8native#:os_type
os_psvita#:os_type
os_ps4#
os_xboxone#:os_type
os_ps3#
os_uwp#:os_type
os_tvos#:os_type
os_switch#:os_type

os_device*:device_type
device_ios_unknown#:device_type
device_ios_iphone#:device_type
device_ios_iphone_retina#:device_type
device_ios_ipad#:device_type
device_ios_ipad_retina#:device_type
device_ios_iphone5#:device_type
device_ios_iphone6#:device_type
device_ios_iphone6plus#:device_type
device_emulator#:device_type
device_tablet#:device_type

os_browser*:browser_type
browser_not_a_browser#:browser_type
browser_unknown#:browser_type
browser_ie#:browser_type
browser_firefox#:browser_type
browser_chrome#:browser_type
browser_safari#:browser_type
browser_safari_mobile#:browser_type
browser_opera#:browser_type
browser_tizen#:browser_type
browser_edge#:browser_type
browser_windows_store#:browser_type
browser_ie_mobile#:browser_type

browser_width*:number
browser_height*:number
browser_input_capture(enable:bool)->void

os_version*:int
os_get_config()->string
os_get_info()->ds_map<string,any>
os_get_language()->string
os_get_region()->string
os_check_permission(permission:string)->android_permission_state
os_permission_denied_dont_request#:android_permission_state
os_permission_denied#:android_permission_state
os_permission_granted#:android_permission_state
os_request_permission(permission:string)->void
os_lock_orientation(flag:bool)->void
display_get_dpi_x()->number
display_get_dpi_y()->number
display_set_gui_size(width:number,height:number)->void
display_set_gui_maximise(?xscale:number,?yscale:number,?xoffset:number,?yoffset:number)£->void
display_set_gui_maximize(?xscale:number,?yscale:number,?xoffset:number,?yoffset:number)$->void
device_mouse_dbclick_enable(enable:bool)->void
display_aa*:int
async_load*:ds_map<string,any>
delta_time*:number
webgl_enabled*:bool

// My job is not to judge that they're still here, just that they're correctly categorized - Anton
of_challenge_win&#:openfeint_challenge
of_challenge_lose&#:openfeint_challenge
of_challenge_tie&#:openfeint_challenge

leaderboard_type_number# //TODO find these
leaderboard_type_time_mins_secs#

#endregion

#region 15 - virtual keys

virtual_key_add(x:number,y:number,w:number,h:number,keycode:int)->virtual_key
virtual_key_hide(id:virtual_key)->void
virtual_key_delete(id:virtual_key)->void
virtual_key_show(id:virtual_key)->void

#endregion

#region 15 - additional draw tricks

draw_enable_drawevent(enable:bool)->void
draw_enable_swf_aa(enable:bool)!->void
draw_set_swf_aa_level(aa_level:number)!->void
draw_get_swf_aa_level()!->number
draw_texture_flush()->void
draw_flush()->void

#endregion

#region 15 - url/async/cloud/ads

shop_leave_rating(text_string:string,yes_string:string,no_string:string,url:string)->void

url_get_domain()->string
url_open(url:string)->void
url_open_ext(url:string,target:string)->void
url_open_full(url:string,target:string,options:string)->void
get_timer()->int

achievement_login()->void
achievement_logout()->void
achievement_post(achievement_name:string,value:number)->void
achievement_increment(achievement_name:string,value:number)->void
achievement_post_score(score_name:string,value:number)->void
achievement_available()->bool
achievement_show_achievements()->bool
achievement_show_leaderboards()->bool
achievement_load_friends()->bool
achievement_load_leaderboard(ident:string,minindex:int,maxindex:int,filter:achievement_leaderboard_filter)->void
achievement_send_challenge(to:string,challengeid:string,score:number,type:achievement_challenge_type,msg:string)->void
achievement_load_progress()->void
achievement_reset()->void
achievement_login_status()->bool
achievement_get_pic(char:string)->void

achievement_show_challenge_notifications(receive_challenge:bool,local_complete:bool,remote_complete:bool)->void
achievement_get_challenges()->void
achievement_event(stringid:string)->void
achievement_show(type:achievement_show_type,val:any)->void
achievement_get_info(userid:string)->void

achievement_our_info#:achievement_async_id
achievement_friends_info#:achievement_async_id
achievement_leaderboard_info#:achievement_async_id
achievement_achievement_info#:achievement_async_id
achievement_filter_all_players#:achievement_leaderboard_filter
achievement_filter_friends_only#:achievement_leaderboard_filter
achievement_filter_favorites_only#:achievement_leaderboard_filter
achievement_type_achievement_challenge#:achievement_challenge_type
achievement_type_score_challenge#:achievement_challenge_type
achievement_pic_loaded#:achievement_async_id

achievement_show_ui#:achievement_show_type
achievement_show_profile#:achievement_show_type
achievement_show_leaderboard#:achievement_show_type
achievement_show_achievement#:achievement_show_type
achievement_show_bank#:achievement_show_type
achievement_show_friend_picker#:achievement_show_type
achievement_show_purchase_prompt#:achievement_show_type


cloud_file_save(filename:string, description:string)->int
cloud_string_save(data:string, description:string)->int
cloud_synchronise()->int

ads_enable(x:number,y:number,num:int)&->void
ads_disable(num:int)&->void
ads_setup(user_uuid:string,ad_app_key:string)&->void
ads_engagement_launch()&->void
ads_engagement_available()&->bool
ads_engagement_active()&->bool
ads_event(stringid:string)&->void
ads_event_preload(stringid:string)&->void

ads_set_reward_callback(callback:string)&->void


ads_get_display_height(slotnum:int)&->number
ads_get_display_width(slotnum:int)&->number
ads_move(x:number,y:number,slotnum:int)&->void

ads_interstitial_available()&->bool
ads_interstitial_display()&->void

#endregion

#region device

device_get_tilt_x()->number
device_get_tilt_y()->number
device_get_tilt_z()->number
device_is_keypad_open()->bool


// Multi-touch functionality
device_mouse_check_button(device:int,button:mouse_button)->bool
device_mouse_check_button_pressed(device:int,button:mouse_button)->bool
device_mouse_check_button_released(device:int,button:mouse_button)->bool
device_mouse_x(device:int)->number
device_mouse_y(device:int)->number
device_mouse_raw_x(device:int)->number
device_mouse_raw_y(device:int)->number
device_mouse_x_to_gui(device:int)->number
device_mouse_y_to_gui(device:int)->number

#endregion

#region IAP

// In-app purchases functionality
iap_activate(ds_list:ds_list<ds_map<string; any>>)->void
iap_status()->iap_system_status
iap_enumerate_products(ds_list:ds_list<ds_map<string; any>>)->void
iap_restore_all()->void
iap_acquire(product_id:string, payload:string)->int
iap_consume(product_id:string)->void
iap_product_details(product_id:string, ds_map:ds_map<string;any>)->void
iap_purchase_details(purchase_id:string, ds_map:ds_map<string;any>)->void

iap_data*:iap_async_id
iap_ev_storeload#:iap_async_id
iap_ev_product#:iap_async_id
iap_ev_purchase#:iap_async_id
iap_ev_consume#:iap_async_id
iap_ev_restore#:iap_async_id

iap_storeload_ok#:iap_async_storeload
iap_storeload_failed#:iap_async_storeload

iap_status_uninitialised#:iap_system_status
iap_status_unavailable#:iap_system_status
iap_status_loading#:iap_system_status
iap_status_available#:iap_system_status
iap_status_processing#:iap_system_status
iap_status_restoring#:iap_system_status

iap_failed#:iap_order_status
iap_unavailable#:iap_order_status
iap_available#:iap_order_status
iap_purchased#:iap_order_status
iap_canceled#:iap_order_status
iap_refunded#:iap_order_status

#endregion

#region gamepad

gamepad_is_supported()->bool
gamepad_get_device_count()->int
gamepad_is_connected(device:int)->bool
gamepad_get_description(device:int)->string
gamepad_get_button_threshold(device:int)->number
gamepad_set_button_threshold(device:int, threshold:number)->void
gamepad_get_axis_deadzone(device:int)->number
gamepad_set_axis_deadzone(device:int, deadzone:number)->void
gamepad_button_count(device:int)->int
gamepad_button_check(device:int, buttonIndex:gamepad_button)->bool
gamepad_button_check_pressed(device:int, buttonIndex:gamepad_button)->bool
gamepad_button_check_released(device:int, buttonIndex:gamepad_button)->bool
gamepad_button_value(device:int, buttonIndex:gamepad_button)->number
gamepad_axis_count(device:int)->int
gamepad_axis_value(device:int, axisIndex:gamepad_button)->number
gamepad_set_vibration(device:int, leftMotorSpeed:number, rightMotorSpeed:number)->void
gamepad_set_colour(index:int,colour:int)£->void
gamepad_set_color(index:int,color:int)$->void

gp_face1#:gamepad_button
gp_face2#:gamepad_button
gp_face3#:gamepad_button
gp_face4#:gamepad_button
gp_shoulderl#:gamepad_button
gp_shoulderr#:gamepad_button
gp_shoulderlb#:gamepad_button
gp_shoulderrb#:gamepad_button
gp_select#:gamepad_button
gp_start#:gamepad_button
gp_stickl#:gamepad_button
gp_stickr#:gamepad_button
gp_padu#:gamepad_button
gp_padd#:gamepad_button
gp_padl#:gamepad_button
gp_padr#:gamepad_button
gp_axislh#:gamepad_button
gp_axislv#:gamepad_button
gp_axisrh#:gamepad_button
gp_axisrv#:gamepad_button

#endregion

os_is_paused()->bool
window_has_focus()->bool
code_is_compiled()->bool

#region async and related

http_get(url:string)->int
http_get_file(url:string, dest:string)->int
http_post_string(url:string, string:string)->int
http_request(url:string, method:string, header_map:ds_map<string;string>, body:string)->int
http_get_request_crossorigin()->string
http_set_request_crossorigin(crossorigin_type:string)->void
json_encode(ds_map:ds_map<string;any>)->string
json_decode(string:string)->ds_map<string,any>

zip_unzip(file:string, destPath:string)->int

load_csv(filename:string)->ds_grid<string>

base64_encode(string:string)->string
base64_decode(string:string)->string
md5_string_unicode(string:string)->string
md5_string_utf8(string:string)->string
md5_file(fname:string)->string
sha1_string_unicode(string:string)->string
sha1_string_utf8(string:string)->string
sha1_file(fname:string)->string

#endregion

os_is_network_connected(?attempt_connection:bool)->bool
os_powersave_enable(enable:bool)->void
analytics_event(string:string)&->void
analytics_event_ext(string:string, ...param_values:string|number)&->void

#region Physics

// World level functions
physics_world_create(PixelToMetreScale:number)->void
physics_world_gravity(gx:number, gy:number)->void
physics_world_update_speed(speed:int)->void
physics_world_update_iterations(iterations:int)->void
physics_world_draw_debug(draw_flags:physics_debug_flag)->void

// Pause
physics_pause_enable(pause:bool)->void

// Fixture related functions
physics_fixture_create()->physics_fixture
physics_fixture_set_kinematic(fixture:physics_fixture)->void
physics_fixture_set_density(fixture:physics_fixture, density:number)->void
physics_fixture_set_awake(fixture:physics_fixture, awake:bool)->void
physics_fixture_set_restitution(fixture:physics_fixture, restitution:number)->void
physics_fixture_set_friction(fixture:physics_fixture,friction:number)->void
physics_fixture_set_collision_group(fixture:physics_fixture, group:int)->void
physics_fixture_set_sensor(fixture:physics_fixture, is_sensor:bool)->void
physics_fixture_set_linear_damping(fixture:physics_fixture, damping:number)->void
physics_fixture_set_angular_damping(fixture:physics_fixture, damping:number)->void
physics_fixture_set_circle_shape(fixture:physics_fixture, circleRadius:number)->void
physics_fixture_set_box_shape(fixture:physics_fixture, halfWidth:number, halfHeight:number)->void
physics_fixture_set_edge_shape(fixture:physics_fixture, x1:number,y1:number,x2:number,y2:number)->void
physics_fixture_set_polygon_shape(fixture:physics_fixture)->void
physics_fixture_set_chain_shape(fixture:physics_fixture, loop:bool)->void
physics_fixture_add_point(fixture:physics_fixture, local_x:number, local_y:number)->void
physics_fixture_bind<T:instance|object>(fixture:physics_fixture, obj:T)->physics_fixture
physics_fixture_bind_ext<T:instance|object>(fixture:physics_fixture, obj:T, xo:number, yo:number)->physics_fixture
physics_fixture_delete(fixture:physics_fixture)->void

// Physics instance manipulation functions
physics_apply_force(xpos:number, ypos:number, xforce:number, yforce:number)->void
physics_apply_impulse(xpos:number, ypos:number, ximpulse:number, yimpulse:number)->void
physics_apply_angular_impulse(impulse:number)->void
physics_apply_local_force(xlocal:number, ylocal:number, xforce_local:number, yforce_local:number)->void
physics_apply_local_impulse(xlocal:number, ylocal:number, ximpulse_local:number, yimpulse_local:number)->void
physics_apply_torque(torque:number)->void
physics_mass_properties(mass:number, local_centre_of_mass_x:number, local_centre_of_mass_y:number, inertia:number)->void
physics_draw_debug()->void
physics_test_overlap<T:instance|object>(x:number, y:number, angle:number, obj:T)->bool
physics_remove_fixture<T>(inst:T, id:physics_fixture)->void
physics_set_friction(fixture:physics_fixture, friction:number)->void
physics_set_density(fixture:physics_fixture, density:number)->void
physics_set_restitution(fixture:physics_fixture, restitution:number)->void
physics_get_friction(fixture:physics_fixture)->number
physics_get_density(fixture:physics_fixture)->number
physics_get_restitution(fixture:physics_fixture)->number

// Joints
physics_joint_distance_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_1_x:number, anchor_1_y:number, anchor_2_x:number, anchor_2_y:number, collideInstances:bool)->physics_joint
physics_joint_rope_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_1_x:number, anchor_1_y:number, anchor_2_x:number, anchor_2_y:number, maxLength:number, collideInstances:bool)->physics_joint
physics_joint_revolute_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_x:number, anchor_y:number, lower_angle_limit:number, upper_angle_limit:number, enable_limit:number, max_motor_torque:number, motor_speed:number, enable_motor:bool, collideInstances:bool)->physics_joint
physics_joint_prismatic_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_x:number, anchor_y:number, axis_x:number, axis_y:number, lower_translation_limit:number, upper_translation_limit:number, enable_limit:bool, max_motor_force:number, motor_speed:number, enable_motor:bool, collideInstances:bool)->physics_joint
physics_joint_pulley_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_1_x:number, anchor_1_y:number, anchor_2_x:number, anchor_2_y:number, local_anchor_1_x:number, local_anchor_1_y:number, local_anchor_2_x:number, local_anchor_2_y:number, ratio:number, collideInstances:bool)->physics_joint
physics_joint_wheel_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_x:number, anchor_y:number, axis_x:number, axis_y:number, enableMotor:bool, max_motor_torque:number, motor_speed:number, freq_hz:number, damping_ratio:number, collideInstances:bool)->physics_joint
physics_joint_weld_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_x:number, anchor_y:number, ref_angle:number, freq_hz:number, damping_ratio:number, collideInstances:bool)->physics_joint
physics_joint_friction_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, anchor_x:number, anchor_y:number, max_force:number, max_torque:number, collideInstances:bool)->physics_joint
physics_joint_gear_create<T0:instance,T1:instance>(inst1:T0, inst2:T1, revoluteJoint:physics_joint, prismaticJoint:physics_joint, ratio:number)->physics_joint
physics_joint_enable_motor(joint:physics_joint, motorState:bool)->void
physics_joint_get_value(joint:physics_joint, field:physics_joint_value)->number|bool
physics_joint_set_value(joint:physics_joint, field:physics_joint_value, value:number|bool)->physics_joint_value
physics_joint_delete(joint:physics_joint)->void

// Physics particles
physics_particle_create(typeflags:physics_particle_flag, x:number, y:number, xv:number, yv:number, col:int, alpha:number, category:int)->physics_particle
physics_particle_delete(ind:physics_particle)->void
physics_particle_delete_region_circle(x:number, y:number, radius:number)->void
physics_particle_delete_region_box(x:number, y:number, halfWidth:number, halfHeight:number)->void
physics_particle_delete_region_poly(pointList:ds_list<number>)->void
physics_particle_set_flags(ind:physics_particle, typeflags:physics_particle_flag)->void
physics_particle_set_category_flags(category:int, typeflags:physics_particle_flag)->void
physics_particle_draw(typemask:physics_particle_flag, category:int, sprite:sprite, subimg:int)->void
physics_particle_draw_ext(typemask:physics_particle_flag, category:int, sprite:sprite, subimg:int, xscale:number, yscale:number, angle:number, col:int, alpha:number)->void
physics_particle_count()->int
physics_particle_get_data(buffer:buffer, dataFlags:physics_particle_data_flag)->void
physics_particle_get_data_particle(ind:physics_particle, buffer:buffer, dataFlags:physics_particle_data_flag)->void

physics_particle_group_begin(typeflags:physics_particle_flag, groupflags:physics_particle_group_flag, x:number, y:number, ang:number, xv:number, yv:number, angVelocity:number, col:int, alpha:number, strength:number, category:int)->void
physics_particle_group_circle(radius:number)->void
physics_particle_group_box(halfWidth:number, halfHeight:number)->void
physics_particle_group_polygon()->void
physics_particle_group_add_point(x:number, y:number)->void
physics_particle_group_end()->physics_particle_group
physics_particle_group_join(to:physics_particle_group, from:physics_particle_group)->void
physics_particle_group_delete(ind:physics_particle_group)->void
physics_particle_group_count(group:physics_particle_group)->int
physics_particle_group_get_data(group:physics_particle_group, buffer:buffer, dataFlags:physics_particle_data_flag)->void
physics_particle_group_get_mass(group:physics_particle_group)->number
physics_particle_group_get_inertia(group:physics_particle_group)->number
physics_particle_group_get_centre_x(group:physics_particle_group)->number
physics_particle_group_get_centre_y(group:physics_particle_group)->number
physics_particle_group_get_vel_x(group:physics_particle_group)->number
physics_particle_group_get_vel_y(group:physics_particle_group)->number
physics_particle_group_get_ang_vel(group:physics_particle_group)->number
physics_particle_group_get_x(group:physics_particle_group)->number
physics_particle_group_get_y(group:physics_particle_group)->number
physics_particle_group_get_angle(group:physics_particle_group)->number
physics_particle_set_group_flags(group:physics_particle_group, groupflags:physics_particle_group_flag)->void
physics_particle_get_group_flags(group:physics_particle_group)->physics_particle_group_flag

physics_particle_get_max_count()->int
physics_particle_get_radius()->number
physics_particle_get_density()->number
physics_particle_get_damping()->number
physics_particle_get_gravity_scale()->number
physics_particle_set_max_count(count:int)->void
physics_particle_set_radius(radius:number)->void
physics_particle_set_density(density:number)->void
physics_particle_set_damping(damping:number)->void
physics_particle_set_gravity_scale(scale:number)->void


// Physics related built in variables (not all can be set)
phy_rotation@:number
phy_position_x@:number
phy_position_y@:number
phy_angular_velocity@:number
phy_linear_velocity_x@:number
phy_linear_velocity_y@:number
phy_speed_x@:number
phy_speed_y@:number
phy_speed*@:number
phy_angular_damping@:number
phy_linear_damping@:number
phy_bullet@:bool
phy_fixed_rotation@:bool
phy_active@:bool
phy_mass*@:number
phy_inertia*@:number
phy_com_x*@:number
phy_com_y*@:number
phy_dynamic*@:bool
phy_kinematic*@:bool
phy_sleeping*@:bool
phy_collision_points*@:int
phy_collision_x*@:number[]
phy_collision_y*@:number[]
phy_col_normal_x*@:number[]
phy_col_normal_y*@:number[]
phy_position_xprevious*@:number
phy_position_yprevious*@:number

phy_joint_anchor_1_x#:physics_joint_value
phy_joint_anchor_1_y#:physics_joint_value
phy_joint_anchor_2_x#:physics_joint_value
phy_joint_anchor_2_y#:physics_joint_value
phy_joint_reaction_force_x#:physics_joint_value
phy_joint_reaction_force_y#:physics_joint_value
phy_joint_reaction_torque#:physics_joint_value
phy_joint_motor_speed#:physics_joint_value
phy_joint_angle#:physics_joint_value
phy_joint_motor_torque#:physics_joint_value
phy_joint_max_motor_torque#:physics_joint_value
phy_joint_translation#:physics_joint_value
phy_joint_speed#:physics_joint_value
phy_joint_motor_force#:physics_joint_value
phy_joint_max_motor_force#:physics_joint_value
phy_joint_length_1#:physics_joint_value
phy_joint_length_2#:physics_joint_value
phy_joint_damping_ratio#:physics_joint_value
phy_joint_frequency#:physics_joint_value
phy_joint_lower_angle_limit#:physics_joint_value
phy_joint_upper_angle_limit#:physics_joint_value
phy_joint_angle_limits#:physics_joint_value
phy_joint_max_length#:physics_joint_value
phy_joint_max_torque#:physics_joint_value
phy_joint_max_force#:physics_joint_value

phy_debug_render_aabb#:physics_debug_flag
phy_debug_render_collision_pairs#:physics_debug_flag
phy_debug_render_coms#:physics_debug_flag
phy_debug_render_core_shapes#:physics_debug_flag
phy_debug_render_joints#:physics_debug_flag
phy_debug_render_obb#:physics_debug_flag
phy_debug_render_shapes#:physics_debug_flag


phy_particle_flag_water#:physics_particle_flag
phy_particle_flag_zombie#:physics_particle_flag
phy_particle_flag_wall#:physics_particle_flag
phy_particle_flag_spring#:physics_particle_flag
phy_particle_flag_elastic#:physics_particle_flag
phy_particle_flag_viscous#:physics_particle_flag
phy_particle_flag_powder#:physics_particle_flag
phy_particle_flag_tensile#:physics_particle_flag
phy_particle_flag_colourmixing#£:physics_particle_flag
phy_particle_flag_colormixing#$:physics_particle_flag

phy_particle_group_flag_solid#:physics_particle_group_flag
phy_particle_group_flag_rigid#:physics_particle_group_flag

phy_particle_data_flag_typeflags#:physics_particle_data_flag
phy_particle_data_flag_position#:physics_particle_data_flag
phy_particle_data_flag_velocity#:physics_particle_data_flag
phy_particle_data_flag_colour#£:physics_particle_data_flag
phy_particle_data_flag_color#$:physics_particle_data_flag
phy_particle_data_flag_category#:physics_particle_data_flag

#endregion

#region Network

network_create_socket(type:network_type)->network_socket
network_create_socket_ext(type:network_type, port:int)->network_socket
network_create_server(type:network_type, port:int, maxclients:int)->network_server
network_create_server_raw(type:network_type, port:int, maxclients:int)->network_server
network_connect(socket:network_socket, url:string, port:int)->int
network_connect_raw(socket:network_socket, url:string, port:int)->int
network_connect_async(socket:network_socket, url:string, port:int)->int
network_connect_raw_async(socket:network_socket, url:string, port:int)->int
network_send_packet(socket:network_socket, bufferid:buffer, size:int)->int
network_send_raw(socket:network_socket, bufferid:buffer, size:int)->int
network_send_broadcast(socket:network_socket, port:int, bufferid:buffer, size:int)->int
network_send_udp(socket:network_socket, URL:string, port:int, bufferid:buffer, size:int)->int
network_send_udp_raw(socket:network_socket, URL:string, port:int, bufferid:buffer, size:int)->int
network_set_timeout(socket:network_socket, read:int, write:int)->void
network_set_config(parameter:network_config, value:network_socket|int|bool)->void
network_resolve(url:string)->string
network_destroy(socket:network_socket|network_server)->void
network_socket_tcp#:network_type
network_socket_udp#:network_type
network_socket_bluetooth#:network_type
network_type_connect#:network_async_id
network_type_disconnect#:network_async_id
network_type_data#:network_async_id
network_type_non_blocking_connect#:network_async_id

network_config_connect_timeout#:network_config
network_config_use_non_blocking_socket#:network_config
network_config_enable_reliable_udp#:network_config
network_config_disable_reliable_udp#:network_config

#endregion

#region Buffers

buffer_create(size:int, buffer_kind:buffer_kind, alignment:int)->buffer
buffer_write(buffer:buffer, type:buffer_type, value:number|string|bool)->int
buffer_read(buffer:buffer, type:buffer_type)->number|string|bool
buffer_seek(buffer:buffer, base:buffer_seek_base, offset:int)->void
buffer_get_surface(buffer:buffer, surface:surface, mode, offset:int, modulo:int)->void
buffer_set_surface(buffer:buffer, surface:surface, mode, offset:int, modulo:int)->void
buffer_delete(buffer:buffer)->void
buffer_exists(buffer:buffer)->bool
buffer_get_type(buffer:buffer)->buffer_kind
buffer_get_alignment(buffer:buffer)->int
buffer_poke(buffer:buffer, offset:int, type:buffer_type, value:number|string|bool)->void
buffer_peek(buffer:buffer, offset:int, type:buffer_type)->number|string|bool
buffer_save(buffer:buffer, filename:string)->void
buffer_save_ext(buffer:buffer, filename:string, offset:int, size:int)->void
buffer_load(filename:string)->buffer
buffer_load_ext(buffer:buffer, filename:string, offset:int)->void
buffer_load_partial(buffer:buffer, filename:string, src_offset:int, src_len:int, dest_offset:int)->void
buffer_copy(src_buffer:buffer, src_offset:int, size:int, dest_buffer:buffer, dest_offset:int)->void
buffer_fill(buffer:buffer, offset:int, type:buffer_type, value:number|string|bool, size:int)->void
buffer_get_size(buffer:buffer)->int
buffer_tell(buffer:buffer)->int
buffer_resize(buffer:buffer, newsize:int)->void
buffer_md5(buffer:buffer, offset:int, size:int)->string
buffer_sha1(buffer:buffer, offset:int, size:int)->string
buffer_crc32(buffer:buffer, offset:int, size:int)->int
buffer_base64_encode(buffer:buffer, offset:int, size:int)->string
buffer_base64_decode(string:string)->buffer
buffer_base64_decode_ext(buffer:buffer, string:string, offset:int)->void
buffer_sizeof(type:buffer_type)->int
buffer_get_address(buffer:buffer)->pointer
buffer_create_from_vertex_buffer(vertex_buffer:vertex_buffer, kind:buffer_kind, alignment:int)->buffer
buffer_create_from_vertex_buffer_ext(vertex_buffer:vertex_buffer, kind:buffer_kind, alignment:int, start_vertex:int, num_vertices:int)->buffer
buffer_copy_from_vertex_buffer(vertex_buffer:vertex_buffer, start_vertex:int, num_vertices:int, dest_buffer:buffer, dest_offset:int)->void
buffer_async_group_begin(groupname:string)->void
buffer_async_group_option(optionname:string,optionvalue:number|bool|string)->void
buffer_async_group_end()->int
buffer_load_async(bufferid:buffer,filename:string,offset:int,size:int)->int
buffer_save_async(bufferid:buffer,filename:string,offset:int,size:int)->int
buffer_compress(bufferid:buffer,offset:int,size:int)->buffer
buffer_decompress(bufferId:buffer)->buffer
buffer_fixed#:buffer_kind
buffer_grow#:buffer_kind
buffer_wrap#:buffer_kind
buffer_fast#:buffer_kind
buffer_vbuffer#:buffer_kind
buffer_u8#:buffer_type
buffer_s8#:buffer_type
buffer_u16#:buffer_type
buffer_s16#:buffer_type
buffer_u32#:buffer_type
buffer_s32#:buffer_type
buffer_u64#:buffer_type
buffer_f16#:buffer_type
buffer_f32#:buffer_type
buffer_f64#:buffer_type
buffer_bool#:buffer_type
buffer_text#:buffer_type
buffer_string#:buffer_type
buffer_seek_start#:buffer_seek_base
buffer_seek_relative#:buffer_seek_base
buffer_seek_end#:buffer_seek_base

#endregion

gml_release_mode(enable:bool)->void
gml_pragma(setting:string,...parameters:string)->void

#region Steam

steam_activate_overlay(overlayIndex:steam_overlay_page)->void
steam_is_overlay_enabled()->bool
steam_is_overlay_activated()->bool
steam_get_persona_name()->string
steam_initialised()->bool
steam_is_cloud_enabled_for_app()->bool
steam_is_cloud_enabled_for_account()->bool
steam_file_persisted(filename:string)->bool
steam_get_quota_total()->int
steam_get_quota_free()->int
steam_file_write(steam_filename:string,data:string,size:int)->int
steam_file_write_file(steam_filename:string,local_filename:string)->int
steam_file_read(filename:string)->string
steam_file_delete(filename:string)->int
steam_file_exists(filename:string)->bool
steam_file_size(filename:string)->int
steam_file_share(filename:string)->int
steam_is_screenshot_requested()->bool
steam_send_screenshot(filename:string,width:int,height:int)->int
steam_is_user_logged_on()->bool
steam_get_user_steam_id()->int // gimped steam_id, dont really have a good way to type it. half_steam_id?
steam_user_owns_dlc(dlc_id:int)->bool
steam_user_installed_dlc(dlc_id:int)->bool
steam_set_achievement(ach_name:string)->void
steam_get_achievement(ach_name:string)->void
steam_clear_achievement(ach_name:string)->void
steam_set_stat_int(stat_name:string,value:int)->void
steam_set_stat_float(stat_name:string,value:number)->void
steam_set_stat_avg_rate(stat_name:string,session_count:number,session_length:number)->void
steam_get_stat_int(stat_name:string)->int
steam_get_stat_float(stat_name:string)->number
steam_get_stat_avg_rate(stat_name:string)->number
steam_reset_all_stats()->void
steam_reset_all_stats_achievements()->void
steam_stats_ready()->bool
steam_create_leaderboard(lb_name:string,sort_method:steam_leaderboard_sort_type,display_type:steam_leaderboard_display_type)->int
steam_upload_score(lb_name:string,score:number)->int
steam_upload_score_ext(lb_name:string,score:number,forceupdate:bool)->int
steam_download_scores_around_user(lb_name:string,range_start:int,range_end:int)->int
steam_download_scores(lb_name:string,start_idx:int,end_idx:int)->int
steam_download_friends_scores(lb_name:string)->int
steam_upload_score_buffer(lb_name:string, score:number, buffer_id:buffer )->int
steam_upload_score_buffer_ext(lb_name:string, score:number, buffer_id:number, forceupdate:bool )->int
steam_current_game_language()->string
steam_available_languages()->string
steam_activate_overlay_browser( url:string )->void
steam_activate_overlay_user( dialog_name:string, steamid:steam_id )->void
steam_activate_overlay_store( app_id:int )->void
steam_get_user_persona_name( steam_id:steam_id )->int

//steam ugc functions
//helpers
steam_get_app_id()->int
steam_get_user_account_id()->steam_id
steam_ugc_download( ugc_handle:steam_ugc, dest_filename:string )->int

//create, edit content
steam_ugc_create_item( consumer_app_id:int, file_type:steam_ugc_type )->int
steam_ugc_start_item_update( consumer_app_id:int, published_file_id:steam_ugc )->int
steam_ugc_set_item_title( ugc_update_handle:steam_ugc, title:string)->bool
steam_ugc_set_item_description( ugc_update_handle:steam_ugc, description:string )->bool
steam_ugc_set_item_visibility(ugc_update_handle:steam_ugc, visibility:steam_ugc_visibility )->bool
steam_ugc_set_item_tags( ugc_update_handle:steam_ugc, tag_array:string[] )->bool
steam_ugc_set_item_content( ugc_update_handle:steam_ugc, directory:string )->bool
steam_ugc_set_item_preview( ugc_update_handle:steam_ugc, image_path:string )->bool
steam_ugc_submit_item_update( ugc_update_handle:steam_ugc, change_note:string )->int
steam_ugc_get_item_update_progress( ugc_update_handle:steam_ugc, info_map:ds_map<string;any> )->bool

//consuming content
steam_ugc_subscribe_item( published_file_id:steam_ugc )->int
steam_ugc_unsubscribe_item( published_file_id:steam_ugc )->int
steam_ugc_num_subscribed_items()->int
steam_ugc_get_subscribed_items( item_list:ds_list<steam_ugc> )->bool
steam_ugc_get_item_install_info( published_file_id:steam_ugc, info_map:ds_map<string;any> )->bool
steam_ugc_get_item_update_info( published_file_id:steam_ugc, info_map:ds_map<string;any> )->bool
steam_ugc_request_item_details( published_file_id:steam_ugc, max_age_seconds:int )->int

//querying content
steam_ugc_create_query_user( list_type:steam_ugc_query_list_type, match_type:steam_ugc_query_match_type, sort_order:steam_ugc_query_sort_order, page:int )->int
steam_ugc_create_query_user_ex( list_type:steam_ugc_query_list_type, match_type:steam_ugc_query_match_type, sort_order:steam_ugc_query_sort_order, page:int, account_id:steam_id, creator_app_id:steam_id, consumer_app_id:int )->int
steam_ugc_create_query_all( query_type:steam_ugc_query_type, match_type:steam_ugc_query_match_type, page:int )->int
steam_ugc_create_query_all_ex( query_type:steam_ugc_query_type, match_type:steam_ugc_query_match_type, page:int, creator_app_id:steam_id, consumer_app_id:int )->int

steam_ugc_query_set_cloud_filename_filter( ugc_query_handle:steam_ugc_query, match_cloud_filename:bool )->bool
steam_ugc_query_set_match_any_tag( ugc_query_handle:steam_ugc_query, match_any_tag:bool )->bool
steam_ugc_query_set_search_text( ugc_query_handle:steam_ugc_query, search_text:string )->bool
steam_ugc_query_set_ranked_by_trend_days( ugc_query:steam_ugc_query, days:number)->bool
steam_ugc_query_add_required_tag( ugc_query_handle:steam_ugc_query, tag_name:string )->bool
steam_ugc_query_add_excluded_tag( ugc_query_handle:steam_ugc_query, tag_name:string )->bool
steam_ugc_query_set_return_long_description( ugc_query_handle:steam_ugc_query, return_long_desc:bool )->bool
steam_ugc_query_set_return_total_only( ugc_query_handle:steam_ugc_query, return_total_only:bool )->bool
steam_ugc_query_set_allow_cached_response( ugc_query_handle:steam_ugc_query, allow_cached_response:bool )->bool
steam_ugc_send_query( ugc_query_handle:steam_ugc_query )->int

//steam constants
ov_friends#:steam_overlay_page
ov_community#:steam_overlay_page
ov_players#:steam_overlay_page
ov_settings#:steam_overlay_page
ov_gamegroup#:steam_overlay_page
ov_achievements#:steam_overlay_page
lb_sort_none#:steam_leaderboard_sort_type
lb_sort_ascending#:steam_leaderboard_sort_type
lb_sort_descending#:steam_leaderboard_sort_type
lb_disp_none#:steam_leaderboard_display_type
lb_disp_numeric#:steam_leaderboard_display_type
lb_disp_time_sec#:steam_leaderboard_display_type
lb_disp_time_ms#:steam_leaderboard_display_type

//steam ugc constants
ugc_result_success#:steam_ugc_async_result
ugc_filetype_community#:steam_ugc_type
ugc_filetype_microtrans#:steam_ugc_type
ugc_visibility_public#:steam_ugc_visibility
ugc_visibility_friends_only#:steam_ugc_visibility
ugc_visibility_private#:steam_ugc_visibility

//ugc query_type constants
ugc_query_RankedByVote#:steam_ugc_query_type
ugc_query_RankedByPublicationDate#:steam_ugc_query_type
ugc_query_AcceptedForGameRankedByAcceptanceDate#:steam_ugc_query_type
ugc_query_RankedByTrend#:steam_ugc_query_type
ugc_query_FavoritedByFriendsRankedByPublicationDate#:steam_ugc_query_type
ugc_query_CreatedByFriendsRankedByPublicationDate#:steam_ugc_query_type
ugc_query_RankedByNumTimesReported#:steam_ugc_query_type
ugc_query_CreatedByFollowedUsersRankedByPublicationDate#:steam_ugc_query_type
ugc_query_NotYetRated#:steam_ugc_query_type
ugc_query_RankedByTotalVotesAsc#:steam_ugc_query_type
ugc_query_RankedByVotesUp#:steam_ugc_query_type
ugc_query_RankedByTextSearch#:steam_ugc_query_type

//ugc query sort_type constants
ugc_sortorder_CreationOrderDesc#:steam_ugc_query_sort_order
ugc_sortorder_CreationOrderAsc#:steam_ugc_query_sort_order
ugc_sortorder_TitleAsc#:steam_ugc_query_sort_order
ugc_sortorder_LastUpdatedDesc#:steam_ugc_query_sort_order
ugc_sortorder_SubscriptionDateDesc#:steam_ugc_query_sort_order
ugc_sortorder_VoteScoreDesc#:steam_ugc_query_sort_order
ugc_sortorder_ForModeration#:steam_ugc_query_sort_order

//ugc query list type constants
ugc_list_Published#:steam_ugc_query_list_type
ugc_list_VotedOn#:steam_ugc_query_list_type
ugc_list_VotedUp#:steam_ugc_query_list_type
ugc_list_VotedDown#:steam_ugc_query_list_type
ugc_list_WillVoteLater#:steam_ugc_query_list_type
ugc_list_Favorited#:steam_ugc_query_list_type
ugc_list_Subscribed#:steam_ugc_query_list_type
ugc_list_UsedOrPlayed#:steam_ugc_query_list_type
ugc_list_Followed#:steam_ugc_query_list_type

//ugc query match_type constants
ugc_match_Items#:steam_ugc_query_match_type
ugc_match_Items_Mtx#:steam_ugc_query_match_type
ugc_match_Items_ReadyToUse#:steam_ugc_query_match_type
ugc_match_Collections#:steam_ugc_query_match_type
ugc_match_Artwork#:steam_ugc_query_match_type
ugc_match_Videos#:steam_ugc_query_match_type
ugc_match_Screenshots#:steam_ugc_query_match_type
ugc_match_AllGuides#:steam_ugc_query_match_type
ugc_match_WebGuides#:steam_ugc_query_match_type
ugc_match_IntegratedGuides#:steam_ugc_query_match_type
ugc_match_UsableInGame#:steam_ugc_query_match_type
ugc_match_ControllerBindings#:steam_ugc_query_match_type

#endregion

#region Shaders

shader_set(shader:shader)->void
shader_get_name(shader:shader)->string
shader_reset()->void
shader_current()->shader
shader_is_compiled(shader:shader)->bool
shader_get_sampler_index(shader:shader,uniform_name:string)->shader_sampler
shader_get_uniform(shader:shader,uniform_name:string)->shader_uniform
shader_set_uniform_i(uniform_id:shader_uniform,val1:int,?val2:int,?val3:int,?val4:int)->void
shader_set_uniform_i_array(uniform_id:shader_uniform,array:int[])->void
shader_set_uniform_f(uniform_id:shader_uniform,val1:number,?val2:number,?val3:number,?val4:number)->void
shader_set_uniform_f_array(uniform_id:shader_uniform,array:number[])->void
shader_set_uniform_matrix(uniform_id:shader_uniform)->void
shader_set_uniform_matrix_array(uniform_id:shader_uniform,array:int[])->void
shader_enable_corner_id(enable:bool)->void
texture_set_stage(sampled_id:shader_sampler, texture_id:texture)->void
texture_get_texel_width(texture_id:texture)->int
texture_get_texel_height(texture_id:texture)->int
shaders_are_supported()->bool

#endregion

#region Vertex buffers

vertex_format_begin()->void
vertex_format_end()->vertex_format
vertex_format_delete(format_id:vertex_format)->void
vertex_format_add_position()->void
vertex_format_add_position_3d()->void
vertex_format_add_colour()£->void
vertex_format_add_color()$->void
vertex_format_add_normal()->void
vertex_format_add_texcoord()->void
vertex_format_add_textcoord()&->void
vertex_format_add_custom(type:vertex_type,usage:vertex_usage)->void

vertex_usage_position#:vertex_usage
vertex_usage_colour#£:vertex_usage
vertex_usage_color#$:vertex_usage
vertex_usage_normal#:vertex_usage
vertex_usage_texcoord#:vertex_usage
vertex_usage_textcoord#&:vertex_usage
vertex_usage_blendweight#:vertex_usage
vertex_usage_blendindices#:vertex_usage
vertex_usage_psize#:vertex_usage
vertex_usage_tangent#:vertex_usage
vertex_usage_binormal#:vertex_usage
vertex_usage_fog#:vertex_usage
vertex_usage_depth#:vertex_usage
vertex_usage_sample#:vertex_usage

vertex_type_float1#:vertex_type
vertex_type_float2#:vertex_type
vertex_type_float3#:vertex_type
vertex_type_float4#:vertex_type
vertex_type_colour#£:vertex_type
vertex_type_color#$:vertex_type
vertex_type_ubyte4#:vertex_type

vertex_create_buffer()->vertex_buffer
vertex_create_buffer_ext(size:int)->vertex_buffer
vertex_delete_buffer(vbuff:vertex_buffer)->void
vertex_begin(vbuff:vertex_buffer,format:vertex_format)->void
vertex_end(vbuff:vertex_buffer)->void
vertex_position(vbuff:vertex_buffer,x:number,y:number)->void
vertex_position_3d(vbuff:vertex_buffer,x:number,y:number,z:number)->void
vertex_colour(vbuff:vertex_buffer,colour:int,alpha:number)£->void
vertex_color(vbuff:vertex_buffer,color:int,alpha:number)$->void
vertex_argb(vbuff:vertex_buffer,argb:int)->void
vertex_texcoord(vbuff:vertex_buffer,u:number,v:number)->void
vertex_normal(vbuff:vertex_buffer,nx:number,ny:number,nz:number)->void
vertex_float1(vbuff:vertex_buffer,f1:number)->void
vertex_float2(vbuff:vertex_buffer,f1:number,f2:number)->void
vertex_float3(vbuff:vertex_buffer,f1:number,f2:number,f3:number)->void
vertex_float4(vbuff:vertex_buffer,f1:number,f2:number,f3:number,f4:number)->void
vertex_ubyte4(vbuff:vertex_buffer,b1:int,b2:int,b3:int,b4:int)->void
vertex_submit(vbuff:vertex_buffer,prim:primitive_type,texture:texture)->void
vertex_freeze(vbuff:vertex_buffer)->void
vertex_get_number(vbuff:vertex_buffer)->int
vertex_get_buffer_size(vbuff:vertex_buffer)->int
vertex_create_buffer_from_buffer(src_buffer:buffer,format:vertex_format)->vertex_buffer
vertex_create_buffer_from_buffer_ext(src_buffer:buffer,format:vertex_format,src_offset:int,num_vertices:int)->vertex_buffer

#endregion

#region push notifications

// Anton:Pretty sure these are all deprecated
push_local_notification(fire_time:datetime, title:string, message:string, data:string)->void
push_get_first_local_notification( ds_map:ds_map<string;string>)->int
push_get_next_local_notification( ds_map:ds_map<string;string> )->int
push_cancel_local_notification( id:int )->void
push_get_application_badge_number()->int
push_set_application_badge_number( num:int )->void

#endregion

#region Spine

// Instance specific
skeleton_animation_set(anim_name:string)!->void
skeleton_animation_get()!->string
skeleton_animation_mix(anim_from:string,anim_to:string,duration:number)!->void
skeleton_animation_set_ext(anim_name:string, track:int)!->void
skeleton_animation_get_ext(track:int)!->string
skeleton_animation_get_duration(anim_name:string)!->number
skeleton_animation_get_frames(anim_name:string)!->int
skeleton_animation_clear(track:int)!->void
skeleton_skin_set(skin_name:string)!->void
skeleton_skin_get()!->string
skeleton_attachment_set(slot:string, attachment:string|sprite)!
skeleton_attachment_get(slot:string)!->string
skeleton_attachment_create(name:string,sprite:sprite,ind:int,xo:number,yo:number,xs:number,ys:number,rot:number)!->int
skeleton_attachment_create_colour(name:string,sprite:sprite,ind:int,xo:number,yo:number,xs:number,ys:number,rot:number,col:int,alpha:number)->int!£
skeleton_attachment_create_color(name:string,sprite:sprite,ind:int,xo:number,yo:number,xs:number,ys:number,rot:number,col:int,alpha:number)->int!$
skeleton_collision_draw_set(val:bool)!->void
skeleton_bone_data_get(bone:string, map:ds_map<string;any>)!->void
skeleton_bone_data_set(bone:string, map:ds_map<string;any>)!->void
skeleton_bone_state_get(bone:string, map:ds_map<string;any>)!->void
skeleton_bone_state_set(bone:string, map:ds_map<string;any>)!->void
skeleton_slot_colour_set(slot:string,col:int,alpha:number)!£->void
skeleton_slot_color_set(slot:string,col:int,alpha:number)!$->void
skeleton_slot_colour_get(slot:string)!£->int
skeleton_slot_color_get(slot:string)!$->int
skeleton_slot_alpha_get(slot:string)!->number
skeleton_find_slot(x:number,y:number,list:ds_list<string>)!->void

skeleton_get_minmax()!->number[]
skeleton_get_num_bounds()!->int
skeleton_get_bounds(index:int)!->number[]
skeleton_animation_get_frame(track:int)!->int
skeleton_animation_set_frame(track:int,index:int)!->void
skeleton_animation_get_event_frames(anim_name:string,event_name:string)!->int[]

// Instance independent!
draw_skeleton(sprite:sprite,animname:string,skinname:string,frame:int,x:number,y:number,xscale:number,yscale:number,rot:number,col:int,alpha:number)!->void

// you know what time it is
draw_skeleton_time(sprite:sprite, animname:string,skinname:string, time:number, x:number,y:number, xscale:number,yscale:number, rot:number, col:int,alpha:number)!->void

draw_skeleton_instance<T>(instance:T, animname:string,skinname:string,frame:int,x:number,y:number,xscale:number,yscale:number,rot:number,col:int,alpha:number)!->void // where T:instance|object
draw_skeleton_collision(sprite:sprite,animname:string,frame:int,x:number,y:number,xscale:number,yscale:number,rot:number,col:int)!->void
draw_enable_skeleton_blendmodes(enable:bool)!->void
draw_get_enable_skeleton_blendmodes()!->bool
skeleton_animation_list(sprite:sprite, list:ds_list<string>)!->void
skeleton_skin_list(sprite:sprite, list:ds_list<string>)!->void
skeleton_bone_list(sprite:sprite, list:ds_list<string>)!->void
skeleton_slot_list(sprite:sprite, list:ds_list<string>)!->void
skeleton_slot_data(sprite:sprite, list:ds_list<ds_map<string;any>>)!->void
skeleton_slot_data_instance(list:ds_list<ds_map<string;any>>)!

#endregion
