#region 2.1

NaN#:number
infinity#:number
GM_runtime_version#:string

#endregion

#region 2.2

is_nan(val:any)->bool
is_infinity(val:any)->bool

variable_instance_get_names<T:instance>(id:T)->string[]
variable_instance_names_count<T:instance>(id:T)->int

#endregion

#region 2.3

string_hash_to_newline(str:string)->string

#endregion

#region 2.4

game_set_speed(value:number,type:gamespeed_type)->void
game_get_speed(type:gamespeed_type)->number
gamespeed_fps#:gamespeed_type
gamespeed_microseconds#:gamespeed_type

#endregion

#region 3.1

in_collision_tree@:bool

#endregion

#region 3.4

collision_point_list<T:object>(x:number,y:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int
collision_rectangle_list<T:object>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int
collision_circle_list<T:object>(x1:number,y1:number,radius:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int
collision_ellipse_list<T:object>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int
collision_line_list<T:object>(x1:number,y1:number,x2:number,y2:number,obj:T,prec:bool,notme:bool,list:ds_list<T>,ordered:bool)->int
instance_position_list<T:object>(x:number,y:number,obj:T,list:ds_list<T>,ordered:bool)->int
instance_place_list<T:object>(x:number,y:number,obj:T,list:ds_list<T>,ordered:bool)->int

#endregion

#region 3.11

font_texture_page_size:int

#endregion

#region 5.1

bboxmode_automatic#:bbox_mode
bboxmode_fullimage#:bbox_mode
bboxmode_manual#:bbox_mode

bboxkind_precise#:bbox_kind
bboxkind_rectangular#:bbox_kind
bboxkind_ellipse#:bbox_kind
bboxkind_diamond#:bbox_kind

// Layer-related built-in variables
layer@:layer

#endregion

#region 5.4

gif_open(width:int,height:int,clear_color:int)->gif
gif_add_surface(gifindex:gif,surfaceindex:surface,delaytime:int,[xoffset]:int,[yoffset]:int,[quantization]:int)->int
gif_save(gif:gif, filename:string)->int
gif_save_buffer(gif:gif)->buffer

#endregion

#region 5.9

view_camera[0..7]:camera[]

#endregion

#region 8.1

sprite_set_speed(ind:sprite,speed:number,type:sprite_speed_type)->void
sprite_get_speed_type(ind:sprite)->sprite_speed_type
sprite_get_speed(ind:sprite)->number

texture_is_ready(tex_id:texture_group|string)->bool
texture_prefetch(tex_id_or_groupname:texture_group|string)->void
texture_flush(tex_id_or_groupname:texture_group|string)->void

texturegroup_get_textures(groupname:string)->texture_group[]
texturegroup_get_sprites(groupname:string)->sprite[]
texturegroup_get_fonts(groupname:string)->font[]
texturegroup_get_tilesets(groupname:string)->tileset[]

texture_debug_messages(debug_level:bool)->void

spritespeed_framespersecond#:sprite_speed_type
spritespeed_framespergameframe#:sprite_speed_type

#endregion

#region 9.9

room_get_camera(ind:room,vind:int)->camera
room_set_camera(ind:room,vind:int,camera:camera)->void

asset_tiles#:asset_type

#endregion

#region 15

matrix_build_identity()->number[]
matrix_build_lookat(xfrom:number,yfrom:number,zfrom:number,xto:number,yto:number,zto:number,xup:number,yup:number,zup:number)->number[]
matrix_build_projection_ortho(width:number,height:number,znear:number,zfar:number)->number[]
matrix_build_projection_perspective(width:number,height:number,znear:number,zfar:number)->number[]
matrix_build_projection_perspective_fov(fov_y:number,aspect:number,znear:number,zfar:number)->number[]
matrix_transform_vertex(matrix:number[], x:number, y:number, z:number)->number[]

matrix_stack_push(matrix:number[])->void
matrix_stack_pop()->void
matrix_stack_set(matrix:number[])->void
matrix_stack_clear()->void
matrix_stack_top()->number[]
matrix_stack_is_empty()->bool

#endregion

#region 15.a

display_set_timing_method(method:display_timing_method)->void
display_get_timing_method()->display_timing_method
tm_sleep#:display_timing_method
tm_countvsyncs#:display_timing_method

display_set_sleep_margin(milliseconds:number)->void
display_get_sleep_margin()->number

#endregion

#region 15 - GPU state

// Constants

lighttype_dir#:draw_lighttype
lighttype_point#:draw_lighttype

gpu_set_blendenable(enable:bool)->void
gpu_set_ztestenable(enable:bool)->void

gpu_set_zfunc(cmp_func:gpu_cmpfunc)->void
gpu_get_zfunc()->gpu_cmpfunc
cmpfunc_never#:gpu_cmpfunc
cmpfunc_less#:gpu_cmpfunc
cmpfunc_equal#:gpu_cmpfunc
cmpfunc_lessequal#:gpu_cmpfunc
cmpfunc_greater#:gpu_cmpfunc
cmpfunc_notequal#:gpu_cmpfunc
cmpfunc_greaterequal#:gpu_cmpfunc
cmpfunc_always#:gpu_cmpfunc

gpu_set_cullmode(cullmode:gpu_cullmode)->void
gpu_get_cullmode()->gpu_cullmode
cull_noculling#:gpu_cullmode
cull_clockwise#:gpu_cullmode
cull_counterclockwise#:gpu_cullmode

gpu_set_zwriteenable(enable:bool)->void
//gpu_set_lightingenable(enable)
gpu_set_fog(array_or_enable:bool|tuple<bool;int;number;number>,?col:number,?start:number,?end:number)->void
gpu_set_blendmode(mode:blendmode)->void
gpu_set_blendmode_ext(src:blendmode_ext|tuple<blendmode_ext;blendmode_ext>,?dest:blendmode_ext)->void
gpu_set_blendmode_ext_sepalpha(src:blendmode_ext|tuple<blendmode_ext;blendmode_ext;blendmode_ext;blendmode_ext>,?dest:blendmode_ext,?srcalpha:blendmode_ext,?destalpha:blendmode_ext)->void
gpu_set_colorwriteenable(red_or_array:bool|bool[],?green*:bool,?blue*:bool,?alpha*:bool)$->void
gpu_set_colourwriteenable(red_or_array:bool|bool[],?green*:bool,?blue*,?alpha*:bool)£->void
gpu_set_alphatestenable(enable:bool)->void
gpu_set_alphatestref(value:int)->void
gpu_set_texfilter(linear:bool)->void
gpu_set_texfilter_ext(sampler_id:shader_sampler,linear:bool)->void
gpu_set_texrepeat(repeat:bool)->void
gpu_set_texrepeat_ext(sampler_id:shader_sampler,repeat:bool)->void
gpu_set_tex_filter(linear:bool)->void
gpu_set_tex_filter_ext(sampler_id:shader_sampler,linear:bool)->void
gpu_set_tex_repeat(repeat:bool)->void
gpu_set_tex_repeat_ext(sampler_id:shader_sampler,repeat:bool)->void

gpu_set_tex_mip_filter(filter:texture_mip_filter)->void
gpu_set_tex_mip_filter_ext(sampler_id:shader_sampler,filter:texture_mip_filter)->void
gpu_set_tex_mip_bias(bias:number)->void
gpu_set_tex_mip_bias_ext(sampler_id:shader_sampler,bias:number)->void
gpu_set_tex_min_mip(minmip:int)->void
gpu_set_tex_min_mip_ext(sampler_id:shader_sampler,minmip:int)->void
gpu_set_tex_max_mip(maxmip:int)->void
gpu_set_tex_max_mip_ext(sampler_id:shader_sampler,maxmip:int)->void
gpu_set_tex_max_aniso(maxaniso:int)->void
gpu_set_tex_max_aniso_ext(sampler_id:shader_sampler,maxaniso:int)->void
gpu_set_tex_mip_enable(setting:texture_mip_state)
gpu_set_tex_mip_enable_ext(sampler_id:shader_sampler,setting:texture_mip_state)

gpu_get_blendenable()->bool
gpu_get_ztestenable()->bool
gpu_get_zwriteenable()->bool
//gpu_get_lightingenable()
gpu_get_fog()->tuple<bool,int,number,number>
gpu_get_blendmode()->blendmode
gpu_get_blendmode_ext()->tuple<blendmode_ext,blendmode_ext>
gpu_get_blendmode_ext_sepalpha()->tuple<blendmode_ext,blendmode_ext,blendmode_ext,blendmode_ext>
gpu_get_blendmode_src()->blendmode_ext
gpu_get_blendmode_dest()->blendmode_ext
gpu_get_blendmode_srcalpha()->blendmode_ext
gpu_get_blendmode_destalpha()->blendmode_ext
gpu_get_colorwriteenable()$->bool
gpu_get_colourwriteenable()£->bool
gpu_get_alphatestenable()->bool
gpu_get_alphatestref()->int
gpu_get_texfilter()->bool
gpu_get_texfilter_ext(sampler_id:shader_sampler)->bool
gpu_get_texrepeat()->bool
gpu_get_texrepeat_ext(sampler_id:shader_sampler)->bool
gpu_get_tex_filter()->bool
gpu_get_tex_filter_ext(sampler_id:shader_sampler)->bool
gpu_get_tex_repeat()->bool
gpu_get_tex_repeat_ext(sampler_id:shader_sampler)->bool

gpu_get_tex_mip_filter()->texture_mip_filter
gpu_get_tex_mip_filter_ext(sampler_id:shader_sampler)->texture_mip_filter
gpu_get_tex_mip_bias()->number
gpu_get_tex_mip_bias_ext(sampler_id:shader_sampler)->number
gpu_get_tex_min_mip()->int
gpu_get_tex_min_mip_ext(sampler_id:shader_sampler)->int
gpu_get_tex_max_mip()->int
gpu_get_tex_max_mip_ext(sampler_id:shader_sampler)->int
gpu_get_tex_max_aniso()->int
gpu_get_tex_max_aniso_ext(sampler_id:shader_sampler)->int
gpu_get_tex_mip_enable()->texture_mip_state
gpu_get_tex_mip_enable_ext(sampler_id:shader_sampler)->texture_mip_state

gpu_push_state()->void
gpu_pop_state()->void

gpu_get_state()->ds_map<string, any>
gpu_set_state(map:ds_map<string; any>)->void

draw_light_define_ambient(col:int)->void
draw_light_define_direction(ind:int,dx:number,dy:number,dz:number,col:int)->void
draw_light_define_point(ind:int,x:number,y:number,z:number,range:number,col:int)->void
draw_light_enable(ind:int,enable:bool)->void
draw_set_lighting(enable:bool)->void

draw_light_get_ambient()->int
draw_light_get(ind:int)->any[]
draw_get_lighting()->bool

#endregion

#region gamepad

gamepad_hat_count(device:int)->int
gamepad_hat_value(device:int, hatIndex:int)->number
gamepad_remove_mapping(device:int)->void
gamepad_test_mapping(device:int, mapping_string:string)->void
gamepad_get_mapping(device:int)->string
gamepad_get_guid(device:int)->string
gamepad_set_option(gamepad_id:int, option_key:string, option_value:any)->void
gamepad_get_option(gamepad_id:int, option_key:string)->any

#endregion

#region Layer functions!

layer_get_id(layer_name:string)->layer
layer_get_id_at_depth(depth:int)->layer
layer_get_depth(layer_id:layer|string)->int
layer_create(depth:int,?name:string)->layer
layer_destroy(layer_id:layer|string)->void
layer_destroy_instances(layer_id:layer|string)->void
layer_add_instance<T>(layer_id:layer|string,instance:T)->void // where T:instance
layer_has_instance<T>(layer_id:layer|string,instance:T)->bool // where T:instance|object
layer_set_visible(layer_id:layer|string,visible:bool)->void
layer_get_visible(layer_id:layer|string)->bool
layer_exists(layer_id:layer|string)->bool
layer_x(layer_id:layer|string,x:number)->void
layer_y(layer_id:layer|string,y:number)->void
layer_get_x(layer_id:layer|string)->number
layer_get_y(layer_id:layer|string)->number
layer_hspeed(layer_id:layer|string,speed:number)->void
layer_vspeed(layer_id:layer|string,speed:number)->void
layer_get_hspeed(layer_id:layer|string)->number
layer_get_vspeed(layer_id:layer|string)->number

layer_script_begin(layer_id:layer|string,script:script)->void
layer_script_end(layer_id:layer|string,script:script)->void

layer_shader(layer_id:layer|string,shader:shader)->void

layer_get_script_begin(layer_id:layer|string)->script
layer_get_script_end(layer_id:layer|string)->script

layer_get_shader(layer_id:layer|string)->shader

layer_set_target_room(room:room)->void
layer_get_target_room()->room
layer_reset_target_room()->void

layer_get_all():layer[]
layer_get_all_elements(layer_id:layer|string)->layer_element[]
layer_get_name(layer_id:layer|string)->string
layer_depth(layer_id:layer|string, depth:int)->void

layer_get_element_layer(element_id:layer_element)->layer
layer_get_element_type(element_id:layer_element)->layer_element_type

layer_element_move(element_id:layer_element,layer_id:layer|string)->void

layer_force_draw_depth(force:bool,depth:number)->void
layer_is_draw_depth_forced()->bool
layer_get_forced_depth()->number

// Layer constants
layerelementtype_undefined#:layer_element_type
layerelementtype_background#:layer_element_type
layerelementtype_instance#:layer_element_type
layerelementtype_oldtilemap#:layer_element_type
layerelementtype_sprite#:layer_element_type
layerelementtype_tilemap#:layer_element_type
layerelementtype_particlesystem#:layer_element_type
layerelementtype_tile#:layer_element_type
layerelementtype_sequence#:layer_element_type

#endregion

#region Background elements

layer_background_get_id(layer_id:layer|string)->layer_background
layer_background_exists(layer_id:layer|string,background_element_id:layer_background)->bool

layer_background_create(layer_id:layer|string,sprite:sprite)->layer_background
layer_background_destroy(background_element_id:layer_background)->void

layer_background_visible(background_element_id:layer_background,visible:bool)->void
layer_background_change(background_element_id:layer_background,sprite:sprite)->void
layer_background_sprite(background_element_id:layer_background,sprite:sprite)->void
layer_background_htiled(background_element_id:layer_background,tiled:bool)->void
layer_background_vtiled(background_element_id:layer_background,tiled:bool)->void
layer_background_stretch(background_element_id:layer_background,stretch:bool)->void
layer_background_yscale(background_element_id:layer_background,yscale:number)->void
layer_background_xscale(background_element_id:layer_background,xscale:number)->void
layer_background_blend(background_element_id:layer_background,col:int)->void
layer_background_alpha(background_element_id:layer_background,alpha:number)->void
layer_background_index(background_element_id:layer_background,image_index:int)->void
layer_background_speed(background_element_id:layer_background,image_speed:number)->void

layer_background_get_visible(background_element_id:layer_background)->bool
layer_background_get_sprite(background_element_id:layer_background)->sprite
layer_background_get_htiled(background_element_id:layer_background)->bool
layer_background_get_vtiled(background_element_id:layer_background)->bool
layer_background_get_stretch(background_element_id:layer_background)->bool
layer_background_get_yscale(background_element_id:layer_background)->number
layer_background_get_xscale(background_element_id:layer_background)->number
layer_background_get_blend(background_element_id:layer_background)->int
layer_background_get_alpha(background_element_id:layer_background)->number
layer_background_get_index(background_element_id:layer_background)->int
layer_background_get_speed(background_element_id:layer_background)->number

#endregion

#region Sprite element

layer_sprite_get_id(layer_id:layer|string,sprite_element_name:string)->layer_sprite
layer_sprite_exists(layer_id:layer|string,sprite_element_id:layer_sprite)->bool

layer_sprite_create(layer_id:layer|string,x:number,y,sprite:number)->layer_sprite
layer_sprite_destroy(sprite_element_id:layer_sprite)->void

layer_sprite_change(sprite_element_id:layer_sprite,sprite:sprite)->void
layer_sprite_index(sprite_element_id:layer_sprite,image_index:int)->void
layer_sprite_speed(sprite_element_id:layer_sprite,image_speed:number)->void
layer_sprite_xscale(sprite_element_id:layer_sprite,scale:number)->void
layer_sprite_yscale(sprite_element_id:layer_sprite,scale:number)->void
layer_sprite_angle(sprite_element_id:layer_sprite,angle:number)->void
layer_sprite_blend(sprite_element_id:layer_sprite,col:int)->void
layer_sprite_alpha(sprite_element_id:layer_sprite,alpha:number)->void
layer_sprite_x(sprite_element_id:layer_sprite,x:number)->void
layer_sprite_y(sprite_element_id:layer_sprite,y:number)->void

layer_sprite_get_sprite(sprite_element_id:layer_sprite)->sprite
layer_sprite_get_index(sprite_element_id:layer_sprite)->int
layer_sprite_get_speed(sprite_element_id:layer_sprite)->number
layer_sprite_get_xscale(sprite_element_id:layer_sprite)->number
layer_sprite_get_yscale(sprite_element_id:layer_sprite)->number
layer_sprite_get_angle(sprite_element_id:layer_sprite)->number
layer_sprite_get_blend(sprite_element_id:layer_sprite)->int
layer_sprite_get_alpha(sprite_element_id:layer_sprite)->number
layer_sprite_get_x(sprite_element_id:layer_sprite)->number
layer_sprite_get_y(sprite_element_id:layer_sprite)->number

#endregion Tile element functions

layer_tile_exists(layer_id:layer|string,tile_element_id:layer_tile_legacy)->bool

layer_tile_create(layer_id:layer|string,x:number,y:number,tileset:sprite,left:number,top:number,width:number,height:number)->layer_tile_legacy
layer_tile_destroy(tile_element_id:layer_tile_legacy)->void

layer_tile_change(tile_element_id:layer_tile_legacy,sprite:sprite)->void
layer_tile_xscale(tile_element_id:layer_tile_legacy,scale:number)->void
layer_tile_yscale(tile_element_id:layer_tile_legacy,scale:number)->void
layer_tile_blend(tile_element_id:layer_tile_legacy,col:int)->void
layer_tile_alpha(tile_element_id:layer_tile_legacy,alpha:number)->void
layer_tile_x(tile_element_id:layer_tile_legacy,x:number)->void
layer_tile_y(tile_element_id:layer_tile_legacy,y:number)->void
layer_tile_region(tile_element_id:layer_tile_legacy,left:number,top:number,width:number,height:number)->void
layer_tile_visible(tile_element_id:layer_tile_legacy,visible:bool)->void

layer_tile_get_sprite(tile_element_id:layer_tile_legacy)->sprite
layer_tile_get_xscale(tile_element_id:layer_tile_legacy)->number
layer_tile_get_yscale(tile_element_id:layer_tile_legacy)->number
layer_tile_get_blend(tile_element_id:layer_tile_legacy)->int
layer_tile_get_alpha(tile_element_id:layer_tile_legacy)->number
layer_tile_get_x(tile_element_id:layer_tile_legacy)->number
layer_tile_get_y(tile_element_id:layer_tile_legacy)->number
layer_tile_get_region(tile_element_id:layer_tile_legacy)->tuple<number,number,number,number>
layer_tile_get_visible(tile_element_id:layer_tile_legacy)->bool

#region Instance element functions
layer_instance_get_instance(instance_element_id:layer_instance)->any // where any:instance

instance_activate_layer(layer_id:layer|string)->bool
instance_deactivate_layer(layer_id:layer|string)->bool

#endregion

#region Tilemap

layer_tilemap_get_id(layer_id:layer|string)->layer_tilemap
layer_tilemap_exists(layer_id:layer|string,tilemap_element_id:layer_tilemap)->bool

layer_tilemap_create(layer_id:layer|string,x:number,y:number,tileset:tileset,width:int,height:int)->layer_tilemap
layer_tilemap_destroy(tilemap_element_id:layer_tilemap)->void

tilemap_tileset(tilemap_element_id:layer_tilemap,tileset:tileset)->void
tilemap_x(tilemap_element_id:layer_tilemap,x:number)->void
tilemap_y(tilemap_element_id:layer_tilemap,y:number)->void

tilemap_set(tilemap_element_id:layer_tilemap,tiledata:tilemap_data,cell_x:int,cell_y:int)->bool
tilemap_set_at_pixel(tilemap_element_id:layer_tilemap,tiledata:tilemap_data,x:number,y:number)->bool

tileset_get_texture(tileset:tileset)->texture
tileset_get_uvs(tileset:tileset)->int[]
tileset_get_name(tileset:tileset)->string

tilemap_get_tileset(tilemap_element_id:layer_tilemap)->tileset
tilemap_get_tile_width(tilemap_element_id:layer_tilemap)->int
tilemap_get_tile_height(tilemap_element_id:layer_tilemap)->int
tilemap_get_width(tilemap_element_id:layer_tilemap)->int
tilemap_get_height(tilemap_element_id:layer_tilemap)->int
tilemap_set_width(tilemap_element_id:layer_tilemap, width:int)->void
tilemap_set_height(tilemap_element_id:layer_tilemap, height:int)->void

tilemap_get_x(tilemap_element_id:layer_tilemap)->number
tilemap_get_y(tilemap_element_id:layer_tilemap)->number

tilemap_get(tilemap_element_id:layer_tilemap,cell_x:int,cell_y:int)->tilemap_data
tilemap_get_at_pixel(tilemap_element_id:layer_tilemap,x:number,y:number)->tilemap_data
tilemap_get_cell_x_at_pixel(tilemap_element_id:layer_tilemap,x:number,y:number)->int
tilemap_get_cell_y_at_pixel(tilemap_element_id:layer_tilemap,x:number,y:number)->int

tilemap_clear(tilemap_element_id:layer_tilemap,tiledata:tilemap_data)->void

draw_tilemap(tilemap_element_id:layer_tilemap,x:number,y:number)->void
draw_tile(tileset:tileset,tiledata:tilemap_data,frame:number,x:number,y:number)->void

tilemap_set_global_mask(mask:tilemap_data)->void
tilemap_get_global_mask()->tilemap_data

tilemap_set_mask(tilemap_element_id:layer_tilemap, mask:tilemap_data)->void
tilemap_get_mask(tilemap_element_id:layer_tilemap)->tilemap_data

tilemap_get_frame(tilemap_element_id:layer_tilemap)->number

// Tile functions
tile_set_empty(tiledata:tilemap_data)->tilemap_data
tile_set_index(tiledata:tilemap_data,tileindex:int)->tilemap_data
tile_set_flip(tiledata:tilemap_data,flip:bool)->tilemap_data
tile_set_mirror(tiledata:tilemap_data,mirror:bool)->tilemap_data
tile_set_rotate(tiledata,rotate:bool)->tilemap_data

tile_get_empty(tiledata:tilemap_data)->bool
tile_get_index(tiledata:tilemap_data)->int
tile_get_flip(tiledata:tilemap_data)->bool
tile_get_mirror(tiledata:tilemap_data)->bool
tile_get_rotate(tiledata:tilemap_data)->bool

// Tile constants
tile_rotate#:tilemap_data
tile_flip#:tilemap_data
tile_mirror#:tilemap_data
tile_index_mask#:tilemap_data

#endregion

#region Camera functions

camera_create()->camera
camera_create_view<T>(room_x:number,room_y:number,width:number,height:number,?angle:number,?object:T,?x_speed:number,?y_speed:number,?x_border:number,?y_border:number)->camera // where T:instance|object
camera_destroy(camera:camera)->void
camera_apply(camera:camera)->void

camera_get_active()->camera
camera_get_default()->camera
camera_set_default(camera:camera)->void

// Setters
camera_set_view_mat(camera:camera,matrix:number[])->void
camera_set_proj_mat(camera:camera,matrix:number[])->void
camera_set_update_script(camera:camera,script:script)->void
camera_set_begin_script(camera:camera,script:script)->void
camera_set_end_script(camera:camera,script:script)->void
camera_set_view_pos(camera:camera,x:number,y:number)->void
camera_set_view_size(camera:camera,width:number,height:number)->void
camera_set_view_speed(camera:camera,x_speed:number,y_speed:number)->void
camera_set_view_border(camera:camera,x_border:number,y_border:number)->void
camera_set_view_angle(camera:camera,angle:number)->void
camera_set_view_target<T>(camera:camera,object:T)->void  // where T:instance|object

// Getters
camera_get_view_mat(camera:camera)->number[]
camera_get_proj_mat(camera:camera)->number[]
camera_get_update_script(camera:camera)->script
camera_get_begin_script(camera:camera)->script
camera_get_end_script(camera:camera)->script

camera_get_view_x(camera:camera)->number
camera_get_view_y(camera:camera)->number
camera_get_view_width(camera:camera)->number
camera_get_view_height(camera:camera)->number
camera_get_view_speed_x(camera:camera)->number
camera_get_view_speed_y(camera:camera)->number
camera_get_view_border_x(camera:camera)->number
camera_get_view_border_y(camera:camera)->number
camera_get_view_angle(camera:camera)->number
camera_get_view_target(camera:camera)->any // where any:instance|object

#endregion

#region View accessors

view_get_camera(view:int)->camera
view_get_visible(view:int)->bool
view_get_xport(view:int)->int
view_get_yport(view:int)->int
view_get_wport(view:int)->int
view_get_hport(view:int)->int
view_get_surface_id(view:int)->surface

view_set_camera(view:int,camera:camera)->void
view_set_visible(view:int,visible:bool)->void
view_set_xport(view:int,xport:int)->void
view_set_yport(view:int,yport:int)->void
view_set_wport(view:int,wport:int)->void
view_set_hport(view:int,hport:int)->void
view_set_surface_id(view:int,surface_id:surface)->void

#endregion

#region Gesture stuff

gesture_drag_time(time:number)->void
gesture_drag_distance(distance:number)->void
gesture_flick_speed(speed:number)->void
gesture_double_tap_time(time:number)->void
gesture_double_tap_distance(distance:number)->void

gesture_pinch_distance(distance:number)->void
gesture_pinch_angle_towards(angle:number)->void
gesture_pinch_angle_away(angle:number)->void
gesture_rotate_time(time:number)->void
gesture_rotate_angle(angle:number)->void

gesture_tap_count(enable:bool)->void

gesture_get_drag_time()->number
gesture_get_drag_distance()->number
gesture_get_flick_speed()->number
gesture_get_double_tap_time()->number
gesture_get_double_tap_distance()->number

gesture_get_pinch_distance()->number
gesture_get_pinch_angle_towards()->number
gesture_get_pinch_angle_away()->number
gesture_get_rotate_time()->number
gesture_get_rotate_angle()->number

gesture_get_tap_count()->bool

#endregion

#region Virtual keyboard

keyboard_virtual_show(virtual_keyboard_type:virtual_keyboard_type, virtual_return_key_type:virtual_keyboard_return_key, auto_capitalization_type:virtual_keyboard_autocapitalization, predictive_text_enabled:bool)
keyboard_virtual_hide()->void
keyboard_virtual_status()->bool
keyboard_virtual_height()->int

kbv_type_default#:virtual_keyboard_type
kbv_type_ascii#:virtual_keyboard_type
kbv_type_url#:virtual_keyboard_type
kbv_type_email#:virtual_keyboard_type
kbv_type_numbers#:virtual_keyboard_type
kbv_type_phone#:virtual_keyboard_type
kbv_type_phone_name#:virtual_keyboard_type

kbv_returnkey_default#:virtual_keyboard_return_key
kbv_returnkey_go#:virtual_keyboard_return_key
kbv_returnkey_google#:virtual_keyboard_return_key
kbv_returnkey_join#:virtual_keyboard_return_key
kbv_returnkey_next#:virtual_keyboard_return_key
kbv_returnkey_route#:virtual_keyboard_return_key
kbv_returnkey_search#:virtual_keyboard_return_key
kbv_returnkey_send#:virtual_keyboard_return_key
kbv_returnkey_yahoo#:virtual_keyboard_return_key
kbv_returnkey_done#:virtual_keyboard_return_key
kbv_returnkey_continue#:virtual_keyboard_return_key
kbv_returnkey_emergency#:virtual_keyboard_return_key

kbv_autocapitalize_none#:virtual_keyboard_autocapitalization
kbv_autocapitalize_words#:virtual_keyboard_autocapitalization
kbv_autocapitalize_sentences#:virtual_keyboard_autocapitalization
kbv_autocapitalize_characters#:virtual_keyboard_autocapitalization

#endregion
