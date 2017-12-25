// Generated at 23.12.2017 12:49:37
true
false
null
undefined
//
:alarm_get(:index):
:alarm_set(:index, value:number)
//{ instance vars
x
y
xprevious
yprevious
xstart
ystart
hspeed
vspeed
direction
speed
friction
gravity
gravity_direction
visible
sprite_index
sprite_width
sprite_height
sprite_xoffset
sprite_yoffset
image_number
image_index
image_speed
depth
image_xscale
image_yscale
image_angle
image_alpha
image_blend
bbox_left*
bbox_right*
bbox_top*
bbox_bottom*
object_index*
id*
solid
persistent
mask_index
//}
//{ Instance
instance_exists(obj:index):
instance_number(obj:index):
instance_position(x:number, y:number, obj:index):
instance_nearest(x:number, y:number, obj:index):
instance_furthest(x:number, y:number, obj:index):
instance_place(x:number, y:number, obj:index):
instance_find(obj:index, n:index);
//}
//{ event_
:event_perform(etype:int, enumb:int)
ev_create = 0
ev_destroy = 1
ev_alarm = 2
ev_step = 3
ev_collision = 4
ev_keyboard = 5
ev_mouse = 6
ev_other = 7
ev_draw = 8
ev_keypress = 9
ev_keyrelease = 10
ev_animation_end = 7
ev_boundary = 1
ev_close_button = 30
ev_draw_begin = 72
ev_draw_end = 73
ev_draw_post = 77
ev_draw_pre = 76
ev_end_of_path = 8
ev_game_end = 3
ev_game_start = 2
ev_global_left_button = 50
ev_global_left_press = 53
ev_global_left_release = 56
ev_global_middle_button = 52
ev_global_middle_press = 55
ev_global_middle_release = 58
ev_global_press = 12
ev_global_release = 13
ev_global_right_button = 51
ev_global_right_press = 54
ev_global_right_release = 57
ev_gui = 64
ev_gui_begin = 74
ev_gui_end = 75
ev_left_button = 0
ev_left_press = 4
ev_left_release = 7
ev_middle_button = 2
ev_middle_press = 6
ev_middle_release = 9
ev_mouse_enter = 10
ev_mouse_leave = 11
ev_mouse_wheel_down = 61
ev_mouse_wheel_up = 60
ev_no_button = 3
ev_no_more_health = 9
ev_no_more_lives = 6
ev_outside = 0
ev_right_button = 1
ev_right_press = 5
ev_right_release = 8
ev_room_end = 5
ev_room_start = 4
ev_step_begin = 1
ev_step_end = 2
ev_step_normal = 0
ev_trigger = 11
ev_user0 = 10
ev_user1 = 11
ev_user10 = 20
ev_user11 = 21
ev_user12 = 22
ev_user13 = 23
ev_user14 = 24
ev_user15 = 25
ev_user2 = 12
ev_user3 = 13
ev_user4 = 14
ev_user5 = 15
ev_user6 = 16
ev_user7 = 17
ev_user8 = 18
ev_user9 = 19
//}
//{ Motion
:motion_set(dir:number, speed:number)
:motion_add(dir:number, speed:number)
:place_free(x:number, y:number):
:place_empty(x:number, y:number):
:place_meeting(x:number, y:number, obj:index):
:place_snapped(hsnap:number, vsnap:number):
:move_snap(hsnap:number, vsnap:number)
:move_towards_point(x:number, y:number, sp:number)
:move_contact_solid(dir:number, maxdist:number)
:move_contact_all(dir:number, maxdist:number)
:move_outside_solid(dir:number, maxdist:number)
:move_outside_all(dir:number, maxdist:number)
:move_bounce_solid(advanced:bool)
:move_bounce_all(advanced:bool)
:move_wrap(hor:bool, vert:bool, margin:number)
:distance_to_point(x:number, y:number):
:distance_to_object(obj:index):
:position_empty(x:number, y:number):
:position_meeting(x:number, y:number, obj:index):
//}
//{ Collision
:collision_point(x:number, y:number, obj:index, prec:bool, notme:bool):
:collision_rectangle(x1:number, y1:number, x2:number, y2:number, obj:index, prec, notme):
:collision_circle(x1:number, y1:number, radius, obj:index, prec, notme):
:collision_ellipse(x1:number, y1:number, x2:number, y2:number, obj:index, prec, notme):
:collision_line(x1:number, y1:number, x2:number, y2:number, obj:index, prec, notme):
//}
//{ Collision helpers
point_in_rectangle(px, py, x1:number, y1:number, x2:number, y2:number):
point_in_triangle(px, py, x1:number, y1:number, x2:number, y2:number, x3:number, y3:number):
point_in_circle(px, py, cx, cy, rad):
rectangle_in_rectangle(sx1:number, sy1:number, sx2:number, sy2:number, dx1:number, dy1:number, dx2:number, dy2:number):
rectangle_in_triangle(sx1:number, sy1:number, sx2:number, sy2:number, x1:number, y1:number, x2:number, y2:number, x3:number, y3:number):
rectangle_in_circle(sx1:number, sy1:number, sx2:number, sy2:number, cx:number, cy:number, rad:number):
//}
//{ Arrays
array_create(size:number):
array_length_1d(value):
array_length(value):
array_push(array, value):
array_find_index(:array, value):
array_join(:array, separator:string):
array_clear(:array, value)
array_clone(:array):
array_slice(:array, start:number, length:number):
array_copy(dest:array, dest_index:number, source:array, source_index:number, length:number):
//}
//{ Math
abs(x:number):
round(x:number):
floor(x:number):
ceil(x:number):
sign(x:number):
frac(x:number):
sqrt(x:number):
sqr(x:number):
exp(x:number):
ln(x:number):
log2(x:number):
log10(x:number):
sin(radian_angle:number):
cos(radian_angle:number):
tan(radian_angle:number):
arcsin(x:number):
arccos(x:number):
arctan(x:number):
arctan2(y:number, x:number):
dsin(degree_angle:number):
dcos(degree_angle:number):
dtan(degree_angle:number):
darcsin(x:number):
darccos(x:number):
darctan(x:number):
darctan2(y:number, x:number):
degtorad(x:number):
radtodeg(x:number):
power(x:number, n:number):
logn(n:number, x:number):
min(x1:number, x2:number, x3:number, ...):
max(x1:number, x2:number, x3:number, ...):
mean(x1:number, x2:number, x3:number, ...):
median(x1:number, x2:number, x3:number, ...):
clamp(val:number, min:number, max:number):
lerp(val1:number, val2:number, amount:number):
dot_product(x1:number, y1:number, x2:number, y2:number):
dot_product_3d(x1:number, y1:number, z1:number, x2:number, y2:number, z2:number):
dot_product_normalised(x1:number, y1:number, x2:number, y2:number):
dot_product_3d_normalised(x1:number, y1:number, z1:number, x2:number, y2:number, z2:number):
angle_difference(src:number, dest:number):
point_distance_3d(x1:number, y1:number, z1:number, x2:number, y2:number, z2:number):
point_distance(x1:number, y1:number, x2:number, y2:number):
point_direction(x1:number, y1:number, x2:number, y2:number):
lengthdir_x(len:number, dir:number):
lengthdir_y(len:number, dir:number):
//}
//{ Conversions
real(val):
string(val):
int64(val):
string_format(val:number,total:number,dec:number):
chr(val):
ansi_char(val):
ord(char):
//}
//{ String operations
string_length(str:string):
string_byte_length(str:string):
string_pos(substr:string, str:string):
string_copy(str:string, index:number, count:number):
string_char_at(str:string, index:number):
string_ord_at(str:string, index:number):
string_byte_at(str:string, index:number):
string_set_byte_at(str:string, index:number, val:number):
string_delete(str:string, index:number, count:number):
string_insert(substr:string, str:string, index:number):
string_lower(str:string):
string_upper(str:string):
string_repeat(str:string, count:number):
string_letters(str:string):
string_digits(str:string):
string_lettersdigits(str:string):
string_replace(str:string, substr:string, newstr:string):
string_replace_all(str:string, substr:string, newstr:string):
string_count(substr:string, str:string):
string_sha1(str:string):
string_sha1_utf8(str:string):
string_md5(str:string):
string_md5_utf8(str:string):
string_lpad(str:string, c:string, len:int):
string_rpad(str:string, c:string, len:int):
string_auto(:number):
string_trim(str:string):
string_ltrim(str:string):
string_rtrim(str:string):
string_split(str:string, delim:string):
string_split_list(str:string, delim:string, ?list:id):
string_save(str:string, path:string):
string_load(path:string):
//}
//{ Color constants
c_aqua = 16776960
c_black = 0
c_blue = 16711680
c_dkgray = 4210752
c_fuchsia = 16711935
c_gray = 8421504
c_green = 32768
c_lime = 65280
c_ltgray = 12632256
c_maroon = 128
c_navy = 8388608
c_olive = 32896
c_purple = 8388736
c_red = 255
c_silver = 12632256
c_teal = 8421376
c_white = 16777215
c_yellow = 65535
c_orange = 4235519
//}
//{ Color functions
make_colour_rgb(red:number, green:number, blue:number):
make_color_rgb(red:number, green:number, blue:number):
make_colour_hsv(hue:number, saturation:number, value:number):
make_color_hsv(hue:number, saturation:number, value:number):
colour_get_red(col):
color_get_red(col):
colour_get_green(col):
color_get_green(col):
colour_get_blue(col):
color_get_blue(col):
colour_get_hue(col):
color_get_hue(col):
colour_get_saturation(col):
color_get_saturation(col):
colour_get_value(col):
color_get_value(col):
merge_colour(col1, col2, amount:number):
merge_color(col1, col2, amount:number):
//}
//{ Drawing - state
draw_set_colour(col:number)
draw_set_color(col:number)
draw_set_alpha(alpha:number)
draw_get_colour():
draw_get_color():
draw_get_alpha():
draw_set_font(font:index)
draw_set_halign(halign:int)
draw_get_halign():
fa_left = 0
fa_center = 1
fa_right = 2
draw_set_valign(valign:int)
draw_get_valign():
fa_top = 0
fa_middle = 1
fa_bottom = 2
string_width(:string):
string_height(:string):
string_width_ext(string:string, sep:number, w:number):
string_height_ext(string:string, sep:number, w:number):
//}
//{ Drawing - texture state
sprite_get_uvs(spr:index, subimg:number):
background_get_uvs(back:index):
font_get_uvs(font:index):
sprite_get_texture(spr:index, subimg:number):
background_get_texture(back:index):
font_get_texture(font:index):
texture_get_width(texid):
texture_get_height(texid):
pr_pointlist = 1
pr_linelist = 2
pr_linestrip = 3
pr_trianglelist = 4
pr_trianglestrip = 5
pr_trianglefan = 6
texture_set_interpolation(linear)
texture_set_blending(blend)
texture_set_repeat(repeat)
//}
//{ Drawing - blend modes
draw_set_blend_mode(mode:int)
bm_normal = 0
bm_add = 1
bm_max = 2
bm_subtract = 3
draw_set_blend_mode_ext(src:int, dest:int)
bm_zero = 1
bm_one = 2
bm_src_colour = 3
bm_inv_src_colour = 4
bm_src_alpha = 5
bm_inv_src_alpha = 6
bm_dest_alpha = 7
bm_inv_dest_alpha = 8
bm_dest_colour = 9
bm_inv_dest_colour = 10
bm_src_alpha_sat = 11
draw_set_colour_write_enable(red:bool, green:bool, blue:bool, alpha:bool)
draw_set_color_write_enable(red:bool, green:bool, blue:bool, alpha:bool)
draw_set_alpha_test(enable:bool)
draw_set_alpha_test_ref_value(value:number)
draw_get_alpha_test():
draw_get_alpha_test_ref_value():
//}
//{ Asset
asset_get_index(name:string):
asset_get_type(name:string):
asset_object = 0
asset_unknown = -1
asset_sprite = 1
asset_sound = 2
asset_room = 3
asset_background = 4
asset_path = 5
asset_script = 6
asset_font = 7
asset_timeline = 8
//}
//{ Sprite
sprite_exists(ind:index):
sprite_get_number(ind:index):
sprite_get_width(ind:index):
sprite_get_height(ind:index):
sprite_get_xoffset(ind:index):
sprite_get_yoffset(ind:index):
sprite_get_bbox_left(ind:index):
sprite_get_bbox_right(ind:index):
sprite_get_bbox_top(ind:index):
sprite_get_bbox_bottom(ind:index):
//}
//{ Object
object_max = 573
object_exists(ind:index):
object_get_name(ind:index):
object_get_sprite(ind:index):
object_get_solid(ind:index):
object_get_visible(ind:index):
object_get_depth(ind:index):
object_get_persistent(ind:index):
object_get_mask(ind:index):
object_get_parent(ind:index):
object_is_ancestor(ind_child:index, ind_parent:index):
//}
//{ Motion planning
:mp_linear_step(x:number, y:number, speed:number, checkall:bool)
:mp_potential_step(x:number, y:number, speed:number, checkall:bool)
:mp_linear_step_object(x:number, y:number, speed:number, obj:index)
:mp_potential_step_object(x:number, y:number, speed:number, obj:index)
//}
/**
 * Creates a copy of the current pseudo-thread that will execute
 * the current script (from the current position) before terminating. Returns
 * `true` to the copy-thread and `false` to the original thread. For example,
 * if (fork()) trace("fork"); else trace("base");
 * will display "fork" in copy-thread and "base" in the original thread.
 * Combined with `wait` instruction, fork() function can be used to implement
 * branching/multi-part behaviours.
 */
fork():
/// Displays value(s) in chat. Intended for debugging.
trace(...values):
trace_time(?caption)
trace_color(text:string, :color)
room_speed
//{
random(x:number)
irandom(x:number)
random_range(min:number, max:number)
irandom_range(min:number, max:number)
choose(...values)
game_set_seed(seed:int):
random_set_seed(seed:int)
random_get_seed():
//}
//{
is_real(value):
is_string(value):
is_array(value):
/// whether a value is a lightweight object ({} \ lq_)
is_object(value):
is_undefined(value):
//}
game_restart()
sleep(ms:number)
game_width:real
game_height:real
game_set_size(w:real, h:real)
game_letterbox:bool
fntM*
fntBigName*
pi = 3.14159265358979
//{ Instance API
instance_create(x:number, y:number, object:object):
:instance_destroy()
:instance_change(_:object, performevents:bool)
:instance_copy(performevents:bool):
/// Removes an instance without triggering it's Destroy-event.
instance_delete(instance:id)
/// Returns whether an instance belongs to given object type
instance_is(instance:id, object:object):
/// Returns array of instances that have varname equal to any of values.
instances_matching(object_or_array, varname:string, ...values):
/// Returns array of instances that have varname not equal to any of values
instances_matching_ne(object_or_array, varname:string, ...values):
/// Returns array of instances that have varname numeric and < the set threshold
instances_matching_lt(object_or_array, varname:string, value:number):
/// Returns array of instances that have varname numeric and > the set threshold
instances_matching_gt(object_or_array, varname:string, value:number):
/// Returns array of instances that have varname numeric and <= the set threshold
instances_matching_le(object_or_array, varname:string, value:number):
/// Returns array of instances that have varname numeric and >= the set threshold
instances_matching_ge(object_or_array, varname:string, value:number):
/// Returns whether an instance has given variable
variable_instance_exists(instance, varname:string):
variable_instance_get(instance, varname:string):
variable_instance_set(instance, varname:string, value)
/// 
point_seen(x:number, y:number, player:int):
point_seen_ext(x:number, y:number, borderx:number, bordery:number, player:int):
//}
sprite_get_name(:sprite):
sprite_add(path:string, subimages:int, x:number, y:number):
sprite_add_base64(base64:string, subimages:int, x:number, y:number):
sprite_add_weapon(path:string, xorig:number, yorig:number):
sprite_add_weapon_base64(base64:string, xorig:number, yorig:number):
sprite_replace(:sprite, path:string, subimages:int, ?x:number, ?y:number)
sprite_replace_base64(:sprite, base64:string, subimages:int, ?x:number, ?y:number)
sprite_replace_image(:sprite, path:string, subimage:int, ?x:number, ?y:number)
sprite_replace_image_base64(:sprite, base64:string, subimages:int, ?x:number, ?y:number)
sprite_duplicate(:sprite):
sprite_duplicate_ext(:sprite, subimg_start:number, subimg_count:number):
sprite_restore(:sprite):
sprite_delete(:sprite):
sprite_collision_mask(:sprite, sepmasks:bool, bboxmode:int, bbleft:number, bbtop:number, bbright:number, bbbottom:number, kind:int, tolerance:number):
sprite_skin(bskin, ...sprites:sprite):
current_time*
current_frame*
//{ ds_list
ds_list_create():
ds_list_destroy(list:index)
ds_list_clear(list:index)
ds_list_size(list:index):
ds_list_shuffle(list:index)
ds_list_find_value(list:index, index:number):
ds_list_set(list:index, index:number, val)
ds_list_add(list:index, ...values)
/// adds each element of the array to the list
ds_list_add_array(list:index, array)
ds_list_insert(list:index, index:number, value)
ds_list_delete(list:index, index:number):
ds_list_find_index(list:index, value):
/// Removes the first occurence of value in a list.
ds_list_remove(list:index, value):
/// Returns a string, containing list' elements separated by given string.
ds_list_join(list:index, separator:string):
/// Creates an array with all current contents of a list
ds_list_to_array(list:index):
//}
//{ ds_map
ds_map_create():
ds_map_destroy(map:index)
ds_map_clear(map:index)
ds_map_size(map:index):
/// Returns an array with all keys of given map
ds_map_keys(map:index):
/// Returns an array with all values of given map
ds_map_values(map:index):
ds_map_find_value(map:index, key):
/// Alias for ds_map_find_value
ds_map_get(map:index, key):
ds_map_set(map:index, key, val)
ds_map_exists(map:index, key)
ds_map_delete(map:index, key)
//}
//{ ds_grid
ds_grid_create(width:number, height:number):
ds_grid_destroy(grid:index)
ds_grid_clear(grid:index, value)
ds_grid_width(grid:index):
ds_grid_height(grid:index):
ds_grid_resize(grid:index, width:number, height:number)
ds_grid_get(grid:index, x:number, y:number):
ds_grid_set(grid:index, x:number, y:number, value)
ds_grid_set_region(grid:index, x1:number, y1:number, x2:number, y2:number, value)
ds_grid_sort(grid:index, column:number, asc:bool)
//}
//{ Lightweight object API
lq_get(obj, field)
lq_defget(obj, field, defValue)
lq_set(obj, field, value)
lq_exists(obj, field)
lq_size(obj)
lq_get_key(obj, fd_index:number)
lq_get_value(obj, fd_index:number)
lq_clone(obj)
//}
//{ JSON functions
/// These actually use TJSON (https://yal.cc/gamemaker-tjson/)
/// and therefore work with arrays/lightweight objects instead of data structures
json_decode(json:string):
json_encode(value, ?indent:string):
json_true*
json_false*
json_error*
json_error_text
//}
//{
surface_create(w:number, h:number):
surface_destroy(sf)
surface_free(sf)
surface_exists(sf)
/// 
surface_resize(sf, w:number, h:number)
surface_get_width(sf):
surface_get_height(sf):
/// 
surface_save(sf, path:string)
surface_save_part(sf, path:string, left:number, top:number, width:number, height:number)
/// 
surface_set_target(sf)
surface_reset_target()
/// Copies the current contents of application_surface to the given surface.
surface_screenshot(sf)
/// 
draw_surface(sf, x:number, y:number)
draw_surface_ext(sf, x:number, y:number, xscale:number, yscale:number, rot:number, :color, alpha:number)
draw_surface_part(sf, left:number, top:number, w:number, h:number, x:number, y:number)
draw_surface_part_ext(sf, left:number, top:number, w:number, h:number, x:number, y:number, xscale:number, yscale:number, :color, alpha:number);
//}
/// Drawing:
:draw_self()
//{ draw_sprite
:draw_sprite(sprite:index, subimg:number, x:number, y:number)
:draw_sprite_pos(sprite:index, subimg:number, x1:number, y1:number, x2:number, y2:number, x3:number, y3:number, x4:number, y4:number, alpha:number)
:draw_sprite_ext(sprite:index, subimg:number, x:number, y:number, xscale:number, yscale:number, rot:number, :color, alpha:number)
:draw_sprite_ext(sprite:index, subimg:number, x:number, y:number, xscale:number, yscale:number, rot:number, :color, alpha:number)
:draw_sprite_stretched(sprite:index, subimg:number, x:number, y:number, w:number, h:number)
:draw_sprite_stretched_ext(sprite:index, subimg:number, x:number, y:number, w:number, h:number, :color, alpha:number)
:draw_sprite_tiled(sprite:index, subimg:number, x:number, y:number)
:draw_sprite_tiled_ext(sprite:index, subimg:number, x:number, y:number, xscale:number, yscale:number, :color, alpha:number)
:draw_sprite_part(sprite:index, subimg:number, left:number, top:number, width:number, height:number, x:number, y:number)
:draw_sprite_part_ext(sprite:index, subimg:number, left:number, top:number, width:number, height:number, x:number, y:number, xscale:number, yscale:number, :color, alpha:number)
:draw_sprite_general(sprite:index, subimg:number, left:number, top:number, width:number, height:number, x:number, y:number, xscale:number, yscale:number, rot:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
//}
//{ draw_background
draw_background(back:index, x:number, y:number)
draw_background_ext(back:index, x:number, y:number, xscale:number, yscale:number, rot:number, :color, alpha:number)
draw_background_stretched(back:index, x:number, y:number, w:number, h:number)
draw_background_stretched_ext(back:index, x:number, y:number, w:number, h:number, :color, alpha:number)
draw_background_tiled(back:index, x:number, y:number)
draw_background_tiled_ext(back:index, x:number, y:number, xscale:number, yscale:number, :color, alpha:number)
draw_background_part(back:index, left:number, top:number, width:number, height:number, x:number, y:number)
draw_background_part_ext(back:index, left:number, top:number, width:number, height:number, x:number, y:number, xscale:number, yscale:number, :color, alpha:number)
draw_background_general(back:index, left:number, top:number, width:number, height:number, x:number, y:number, xscale:number, yscale:number, rot:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
//}
//{ draw_ basics
draw_clear(:color)
draw_clear_alpha(:color, alpha:number)
draw_point(x:number, y:number)
draw_line(x1:number, y1:number, x2:number, y2:number)
draw_line_width(x1:number, y1:number, x2:number, y2:number, w:number)
draw_rectangle(x1:number, y1:number, x2:number, y2:number, outline:bool)
draw_roundrect(x1:number, y1:number, x2:number, y2:number, outline:bool)
draw_roundrect_ext(x1:number, y1:number, x2:number, y2:number, radiusx:number, radiusy:number, outline:bool)
draw_triangle(x1:number, y1:number, x2:number, y2:number, x3:number, y3:number, outline:bool)
draw_circle(x:number, y:number, r:number, outline:bool)
draw_ellipse(x1:number, y1:number, x2:number, y2:number, outline:bool)
draw_set_circle_precision(precision:number)
draw_arrow(x1:number, y1:number, x2:number, y2:number, size:number)
draw_button(x1:number, y1:number, x2:number, y2:number, up:bool)
:draw_path(path:index, x:number, y:number, absolute:bool)
draw_healthbar(x1:number, y1:number, x2:number, y2:number, amount:number, backcol, mincol:color, maxcol:color, direction:number, showback:bool, showborder:bool)
//}
//{ draw_text
draw_text(x:number, y:number, string:string)
draw_text_ext(x:number, y:number, string, sep:number, w:number)
draw_text_transformed(x:number, y:number, string:string, xscale:number, yscale:number, angle:number)
draw_text_ext_transformed(x:number, y:number, string:string, sep, w:number, xscale:number, yscale:number, angle:number)
draw_text_colour(x:number, y:number, string:string, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_color(x:number, y:number, string:string, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_ext_colour(x:number, y:number, string:string, sep, w:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_ext_color(x:number, y:number, string:string, sep, w:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_transformed_colour(x:number, y:number, string:string, xscale:number, yscale:number, angle:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_transformed_color(x:number, y:number, string:string, xscale:number, yscale:number, angle:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_ext_transformed_colour(x:number, y:number, string:string, sep, w:number, xscale:number, yscale:number, angle:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
draw_text_ext_transformed_color(x:number, y:number, string:string, sep, w:number, xscale:number, yscale:number, angle:number, c1:color, c2:color, c3:color, c4:color, alpha:number)
/// Draws text with @tags (see doc)
draw_text_nt(x:number, y:number, :string)
draw_tooltip(x:number, y:number, :string)
draw_text_shadow(x:number, y:number, :string)
//}
//{ draw_ advanced
draw_point_colour(x:number, y:number, col1:color)
draw_point_color(x:number, y:number, col1:color)
draw_line_colour(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color)
draw_line_color(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color)
draw_line_width_colour(x1:number, y1:number, x2:number, y2:number, w:number, col1:color, col2:color)
draw_line_width_color(x1:number, y1:number, x2:number, y2:number, w:number, col1:color, col2:color)
draw_rectangle_colour(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color, col3:color, col4:color, outline:bool)
draw_rectangle_color(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color, col3:color, col4:color, outline:bool)
draw_roundrect_colour(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color, outline:bool)
draw_roundrect_color(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color, outline:bool)
draw_roundrect_colour_ext(x1:number, y1:number, x2:number, y2:number, radiusx:number, radiusy:number, col1:color, col2:color, outline:bool)
draw_roundrect_color_ext(x1:number, y1:number, x2:number, y2:number, radiusx:number, radiusy:number, col1:color, col2:color, outline:bool)
draw_triangle_colour(x1:number, y1:number, x2:number, y2:number, x3:number, y3:number, col1:color, col2:color, col3:color, outline:bool)
draw_triangle_color(x1:number, y1:number, x2:number, y2:number, x3:number, y3:number, col1:color, col2:color, col3:color, outline:bool)
draw_circle_colour(x:number, y:number, r:number, col1:color, col2:color, outline:bool)
draw_circle_color(x:number, y:number, r:number, col1:color, col2:color, outline:bool)
draw_ellipse_colour(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color, outline:bool)
draw_ellipse_color(x1:number, y1:number, x2:number, y2:number, col1:color, col2:color, outline:bool)
draw_rect_ext(x:number, y:number, width:number, height:number, :color, alpha:number)
//}
//{ draw_primitive
draw_primitive_begin(kind:int)
draw_vertex(x:number, y:number)
draw_vertex_colour(x:number, y:number, col:color, alpha:number)
draw_vertex_color(x:number, y:number, col:color, alpha:number)
draw_primitive_end()
draw_primitive_begin_texture(kind:int, texid)
draw_vertex_texture(x:number, y:number, xtex:number, ytex:number)
draw_vertex_texture_colour(x:number, y:number, xtex:number, ytex:number, col:color, alpha:number)
draw_vertex_texture_color(x:number, y:number, xtex:number, ytex:number, col:color, alpha:number)
//}
//{ Visibility API
/// Changes whether subsequently drawn graphics should be visible to given player
draw_set_visible(player:int, visible:bool)
/// Same as above, but applies to all players
draw_set_visible_all(visible:bool)
/// Returns state set via above two
draw_get_visible(player:int):
/// Has subsequently drawn graphics visible to player if a rectangle is within local view bounds
draw_set_visible_bbox(player:int, left:number, top:number, right:number, bottom:number)
/// Has subsequently drawn graphics visible to all players if a rectangle is within local view bounds
draw_set_visible_bbox_all(left:number, top:number, right:number, bottom:number)
//}
//{
d3d_set_fog(enable:bool, color:color, start:number, end:number)
draw_set_fog(enable:bool, color:color, start:number, end:number)
//}
/// Changes the transformation matrix for subsequently drawn graphics. Mode can be one of following:
/// 0: No offset
/// 1: View' offset
/// 2: Player HUD (index specifies player)
draw_set_projection(mode:int, ?index:int)
draw_reset_projection()
background_color
//{ Mod API
/// NTT mod version
game_version = 0
mod_exists(type:string, name:string):
/// Returns an array containing names of loaded mods of given type.
mod_get_names(type:string):
mod_variable_exists(type:string, name:string, varName:string):
mod_variable_get(type:string, name:string, varName:string):
mod_variable_set(type:string, name:string, varName:string, value:number)
mod_script_exists(type:string, name:string, scrName:string):
:mod_script_call(type:string, name:string, scrName:string, ...args):
//{
mod_sideload():
mod_load(path:string):
mod_loadlive(path:string):
mod_loadtext(path:string):
mod_unload(path:string):
//}
//}
//{
script_ref_create(script:index, ...args):
script_ref_create_ext(type:string, name:string, script:string, ...args):
script_ref_call(ref, ...args):
script_bind_begin_step(script, depth:number, ...args)
script_bind_step(script, depth:number, ...args)
script_bind_end_step(script, depth:number, ...args)
script_bind_draw(script, depth:number, ...args)
//}
//{ Audio API
sound_loop(:sound):
sound_play(:sound):
sound_play_pitch(:sound, pitch:number):
sound_play_pitchvol(:sound, pitch:number, volume:number):
/// Plays a sound for gunshot.
/// The way audio system works in Nuclear Throne is that non-gun audio is temporarily
/// faded (to `fade` volume) for a few moments after each shot.
/// Regular guns use fade=0.3, small guns use fade=0.6, large guns use fade=-0.5
sound_play_gun(:sound, pitch_spread:number, fade:number):
sound_play_hit(:sound, pitch_spread:number):
sound_play_hit_big(:sound, pitch_spread:number):
sound_stop(:sound)
sound_stop_all()
sound_set_track_position(:sound, seconds:number)
sound_pitch(:sound, pitch:number)
sound_volume(:sound, volume:number)
sound_exists(:sound):
sound_get_name(:sound):
sound_play_music(:sound)
sound_play_ambient(:sound)
sound_add(path:string):
sound_delete(:sound)
/// note: you can't replace sounds loaded by mods - change variables for that.
sound_assign(original:sound, replace:sound):
sound_replace(original:sound, path:string):
sound_restore(original:sound)
//}
//{ Player API
/**
 * A constant that holds the number of player slots (2) used in player functions. 
 * Intended to be used instead of hardcoding `2` everywhere.
 * e.g. for (var p = 0; p < maxp; p++) { ... }
 */
maxp = 4
button_check(player:int, button:string):
button_pressed(player:int, button:string):
button_released(player:int, button:string):
mouse_x[player]*
mouse_y[player]*
view_xview[player]*
view_yview[player]*
view_object[player]:id
view_pan_factor[player]
view_shake[player]:number
view_shake_at(x:number, y:number, amount:number)
view_shake_max_at(x:number, y:number, amount:number)
/// Finds a player instance by player index
player_find(player:int):
player_get_color(player:int):
player_is_active(player:int):
player_get_alias(player:int):
player_get_outlines(player:int):
player_get_uid(player:int):
player_get_race(player:int):
player_get_race_id(player:int):
player_set_race(player:int, race)
player_get_race_pick(player:int):
player_get_race_pick_id(player:int):
player_set_race_pick(player:int, race)
player_get_skin(player:int):
player_set_skin(player:int, skin)
player_count_race(race):
player_get_show_cursor(of_player:int, to_player:int):
player_set_show_cursor(of_player:int, to_player:int, show:bool)
player_get_show_marker(of_player:int, to_player:int):
player_set_show_marker(of_player:int, to_player:int, show:bool)
player_get_show_hud(of_player:int, to_player:int):
player_set_show_hud(of_player:int, to_player:int, show:bool)
player_get_show_prompts(of_player:int, to_player:int)
player_set_show_prompts(of_player:int, to_player:int, show:bool)
player_get_show_skills(to_player:int):
player_set_show_skills(to_player:int, show:bool)
:player_fire(?direction:number)
:player_fire_ext(?direction:number, ?wep, ?x:number, ?y:number, ?team:number, ?creator:id, ...):
//}
//{ Weapon API
weapon_get_name(wep):
weapon_get_area(wep):
weapon_get_sprt(wep):
weapon_get_sprite(wep):
weapon_get_sprt_hud(wep):
weapon_get_auto(wep):
weapon_get_load(wep):
weapon_get_type(wep):
weapon_get_cost(wep):
weapon_get_rads(wep):
weapon_get_swap(wep):
weapon_get_text(wep):
weapon_is_melee(wep):
weapon_get_gold(wep):
weapon_get_laser_sight(wep):
/// setters - only work for built-in weapons:
weapon_set_name(wep:index, :string)
weapon_set_area(wep:index, :number)
weapon_set_sprt(wep:index, :sprite)
weapon_set_sprite(wep:index, :sprite)
weapon_set_auto(wep:index, :bool)
weapon_set_load(wep:index, :number)
weapon_set_type(wep:index, :index)
weapon_set_cost(wep:index, :number)
weapon_set_swap(wep:index, :sound)
weapon_set_text(wep:index, :string)
/// Can be used in weapon_fire for common weapon effects
:weapon_post(wkick:number, shift:number, shake:number)
/// Adds all weapons (regular and modded) within the given area range to a list.
/// Returns the number of weapons found.
:weapon_get_list(list:index, ?minarea:number, ?maxarea:number):
//}
//{ Projectile helpers
/// Checks if a bullet can hit the given target (team comparison)
:projectile_canhit(hitme:id):
/// Checks if a swing can hit the given target (team and iframe comparison)
:projectile_canhit_melee(hitme:id):
/// Checks if a non-player attack can hit the given target (team and hp; iframes for players)
:projectile_canhit_np(hitme:id):
/// Deals damage to given entity, pushing it in given direction if needed.
:projectile_hit(hitme:id, damage:number, ?knockback:number, ?kb_dir:number)
/// Deals damage to given entity, pushing it away from the projectile.
:projectile_hit_push(hitme:id, damage:number, knockback:number)
/// Deals damage to given entity as enemy projectiles would (freeze frames for player hits).
:projectile_hit_np(hitme:id, damage:number, knockback:number, freeze_ms:number)
/// Deals damage to given entity as if by global source (mutations/active/lightning/...)
/// hurt_snd is 0 for no sound, 1 for regular sound, 2 for 'hit by large object' sound
projectile_hit_raw(hitme:id, damage:number, hurt_snd:int)
//}
//{ Skill API
skill_get(skill):
skill_set(skill, value:bool):
skill_get_at(index:int):
skill_clear()
skill_get_active(skill):
skill_set_active(skill, active:bool)
skill_get_name(skill)
ultra_get(race, index:int)
ultra_set(race, index:int, active:bool)
ultra_count(race):
//}
//{ Race API
race_get_active(race):
race_set_active(race, active:bool)
race_get_id(race)
race_get_name(race)
race_get_alias(race)
//}
//{ Level API
area_get_background_color(area:int)
area_get_shadow_color(area:int)
//}
file_load(...paths):
file_unload(...paths)
file_loaded(path:string):
file_exists(path:string):
file_size(path:string):
file_md5(path:string):
file_sha1(path:string):
file_delete(path:string):
file_download(url:string, path:string)
file_load_bytes(path:string):
file_save_bytes(path:string, bytes):
file_save_bytes_ext(path:string, bytes, start:int, length:int):
file_find_all(path:string, result:array, ?depth:int):
//{ Translation API
loc(key:string, defvalue:string):
loc_set(key:string, value:string)
//}
wep_none = 0
wep_revolver = 1
wep_triple_machinegun = 2
wep_wrench = 3
wep_machinegun = 4
wep_shotgun = 5
wep_crossbow = 6
wep_grenade_launcher = 7
wep_double_shotgun = 8
wep_minigun = 9
wep_auto_shotgun = 10
wep_auto_crossbow = 11
wep_super_crossbow = 12
wep_shovel = 13
wep_bazooka = 14
wep_sticky_launcher = 15
wep_smg = 16
wep_assault_rifle = 17
wep_disc_gun = 18
wep_laser_pistol = 19
wep_laser_rifle = 20
wep_slugger = 21
wep_gatling_slugger = 22
wep_assault_slugger = 23
wep_energy_sword = 24
wep_super_slugger = 25
wep_hyper_rifle = 26
wep_screwdriver = 27
wep_laser_minigun = 28
wep_blood_launcher = 29
wep_splinter_gun = 30
wep_toxic_bow = 31
wep_sentry_gun = 32
wep_wave_gun = 33
wep_plasma_gun = 34
wep_plasma_cannon = 35
wep_energy_hammer = 36
wep_jackhammer = 37
wep_flak_cannon = 38
wep_golden_revolver = 39
wep_golden_wrench = 40
wep_golden_machinegun = 41
wep_golden_shotgun = 42
wep_golden_crossbow = 43
wep_golden_grenade_launcher = 44
wep_golden_laser_pistol = 45
wep_chicken_sword = 46
wep_nuke_launcher = 47
wep_ion_cannon = 48
wep_quadruple_machinegun = 49
wep_flamethrower = 50
wep_dragon = 51
wep_flare_gun = 52
wep_energy_screwdriver = 53
wep_hyper_launcher = 54
wep_laser_cannon = 55
wep_rusty_revolver = 56
wep_lightning_pistol = 57
wep_lightning_rifle = 58
wep_lightning_shotgun = 59
wep_super_flak_cannon = 60
wep_sawed_off_shotgun = 61
wep_splinter_pistol = 62
wep_super_splinter_gun = 63
wep_lightning_smg = 64
wep_smart_gun = 65
wep_heavy_crossbow = 66
wep_blood_hammer = 67
wep_lightning_cannon = 68
wep_pop_gun = 69
wep_plasma_rifle = 70
wep_pop_rifle = 71
wep_toxic_launcher = 72
wep_flame_cannon = 73
wep_lightning_hammer = 74
wep_flame_shotgun = 75
wep_double_flame_shotgun = 76
wep_auto_flame_shotgun = 77
wep_cluster_launcher = 78
wep_grenade_shotgun = 79
wep_grenade_rifle = 80
wep_rogue_rifle = 81
wep_party_gun = 82
wep_double_minigun = 83
wep_gatling_bazooka = 84
wep_auto_grenade_shotgun = 85
wep_ultra_revolver = 86
wep_ultra_laser_pistol = 87
wep_sledgehammer = 88
wep_heavy_revolver = 89
wep_heavy_machinegun = 90
wep_heavy_slugger = 91
wep_ultra_shovel = 92
wep_ultra_shotgun = 93
wep_ultra_crossbow = 94
wep_ultra_grenade_launcher = 95
wep_plasma_minigun = 96
wep_devastator = 97
wep_golden_plasma_gun = 98
wep_golden_slugger = 99
wep_golden_splinter_gun = 100
wep_golden_screwdriver = 101
wep_golden_bazooka = 102
wep_golden_assault_rifle = 103
wep_super_disc_gun = 104
wep_heavy_auto_crossbow = 105
wep_heavy_assault_rifle = 106
wep_blood_cannon = 107
wep_dog_spin_attack = 108
wep_dog_missile = 109
wep_incinerator = 110
wep_super_plasma_cannon = 111
wep_seeker_pistol = 112
wep_seeker_shotgun = 113
wep_eraser = 114
wep_guitar = 115
wep_bouncer_smg = 116
wep_bouncer_shotgun = 117
wep_hyper_slugger = 118
wep_super_bazooka = 119
wep_frog_pistol = 120
wep_black_sword = 121
wep_golden_nuke_launcher = 122
wep_golden_disc_gun = 123
wep_heavy_grenade_launcher = 124
wep_gun_gun = 125
wep_eggplant = 126
wep_golden_frog_pistol = 127
mut_none = 0
mut_rhino_skin = 1
mut_extra_feet = 2
mut_plutonium_hunger = 3
mut_rabbit_paw = 4
mut_throne_butt = 5
mut_lucky_shot = 6
mut_bloodlust = 7
mut_gamma_guts = 8
mut_second_stomach = 9
mut_back_muscle = 10
mut_scarier_face = 11
mut_euphoria = 12
mut_long_arms = 13
mut_boiling_veins = 14
mut_shotgun_shoulders = 15
mut_recycle_gland = 16
mut_laser_brain = 17
mut_last_wish = 18
mut_eagle_eyes = 19
mut_impact_wrists = 20
mut_bolt_marrow = 21
mut_stress = 22
mut_trigger_fingers = 23
mut_sharp_teeth = 24
mut_patience = 25
mut_hammerhead = 26
mut_strong_spirit = 27
mut_open_mind = 28
mut_heavy_heart = 29
char_random = 0
char_fish = 1
char_crystal = 2
char_eyes = 3
char_melting = 4
char_plant = 5
char_venuz = 6
char_steroids = 7
char_robot = 8
char_chicken = 9
char_rebel = 10
char_horror = 11
char_rogue = 12
char_bigdog = 13
char_skeleton = 14
char_frog = 15
crwn_random = 0
crwn_none = 1
crwn_death = 2
crwn_life = 3
crwn_haste = 4
crwn_guns = 5
crwn_hatred = 6
crwn_blood = 7
crwn_destiny = 8
crwn_love = 9
crwn_luck = 10
crwn_curses = 11
crwn_risk = 12
crwn_protection = 13
mod_current = ""
