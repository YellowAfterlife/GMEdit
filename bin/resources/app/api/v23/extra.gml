// Here you can add any additional API entries,
// such as those not shown in auto-completion.
array_get(array, i)
array_set(array, i, val)
array_set_2D(array, i, k, val)

??audio_play_sound_pos_t
x?:number
y?:number
z?:number
falloff_ref?:number
falloff_max?:number
falloff_factor?:number

??audio_play_sound_ext_t
sound?:sound
priority?:number
loop?:bool
gain?:number
offset?:number
pitch?:number
listener_mask?:int
emitter?:audio_emitter
position?:audio_play_sound_pos_t

??font_info
ascender?:number
ascenderOffset?:number
size?:number
spriteIndex?:sprite
texture?:texture
name?:string
bold?:bool
italic?:bool
glyphs?:Array<font_info_glyph>
sdfEnabled?:bool
sdfSpread?:number
effectsEnabled?:bool
effectParams?:font_effect_params

??font_info_glyph
char?:int
x?:number
y?:number
w?:number
h?:number
shift?:number
offset?:number
kerning?:Array<int>

??font_effect_params
thickness?:number
coreColour?:int
coreAlpha?:number
glowEnable?:bool
glowColour?:int
glowAlpha?:number
outlineEnable?:bool
outlineDistance?:number
outlineColour?:int
outlineAlpha?:number
dropShadowEnable?:bool
dropShadowSoftness?:number
dropShadowOffsetX?:number
dropShadowOffsetY?:number
dropShadowColour?:int
dropShadowAlpha?:number

??font_glyph_cache
x?:number
y?:number

??sprite_info
width?:int
height?:int
xoffset?:int
yoffset?:int
transparent?:bool
smooth?:bool
type?:int
bbox_left?:int
bbox_top?:int
bbox_right?:int
bbox_bottom?:int
name?:string
num_subimages?:int
use_mask?:bool
num_masks?:int
rotated_bounds?:bool
nineslice?:nineslice
messages?:Array<sprite_message>
frame_info?:Array<sprite_frame_info>|undefined
frame_speed?:number
frame_type?:sprite_speed_type
frames?:Array<sprite_frame>
num_atlas?:int
atlas_texture?:Array<texture>
premultiplied?:bool
animation_names?:Array<string>
skin_names?:Array<string>
bones?:Array<sprite_spine_bone>
slots?:Array<sprite_spine_slot>

??sprite_message
frame?:int
message?:string

??sprite_frame_info
frame?:int
duration?:int
image_index?:int

??sprite_frame
x?:int
y?:int
w?:int
h?:int
texture?:texture
original_width?:int
original_height?:int
crop_width?:int
crop_height?:int
x_offset?:int
y_offset?:int

??sprite_spine_bone
parent?:string
name?:string
index?:int
length?:number
x?:number
y?:number
rotation?:number
scale_x?:number
scale_y?:number
shear_x?:number
shear_y?:number
transform_mode?:int

??sprite_spine_slot
name?:string
index?:int
bone?:string
attachment?:string
red?:number
green?:number
blue?:number
alpha?:number
blend_mode?:int
dark_red?:number
dark_green?:number
dark_blue?:number
dark_alpha?:number
attachments?:Array<string>

??nineslice
enabled?:bool
left?:int
right?:int
top?:int
bottom?:int
tilemode?:ckarray<nineslice_tile_index,nineslice_tile_mode>

??room_info
width?:int
height?:int
creationCode?:function
{}
physicsWorld?:bool
physicsGravityX?:number
physicsGravityY?:number
physicsPixToMeters?:number
persistent?:bool
enableViews?:bool
clearDisplayBuffer?:bool
clearViewportBackground?:bool
colour?:int
instances?:Array<room_info_instance>
layers?:Array<room_info_layer>
views?:Array<room_info_view>

??room_info_instance
id?:instance
object_index?:string
x?:number
y?:number
xscale?:number
yscale?:number
angle?:number
image_index?:int
image_speed?:number
colour?:int
creation_code?:function
{}
pre_creation_code?:function
{}

??room_info_layer
id?:int
name?:string
visible?:bool
depth?:number
xoffset?:number
yoffset?:number
hspeed?:number
vspeed?:number
effectEnabled?:bool
effectToBeEnabled?:bool
effect?:fx_struct
shaderID?:shader
elements?:Array<room_info_layer_element>

??room_info_view
visible?:bool
cameraID?:camera
xview?:int
yview?:int
wview?:int
hview?:int
hspeed?:number
vspeed?:number
xport?:int
yport?:int
wport?:int
hport?:int
object?:object
hborder?:int
vborder?:int

??room_info_layer_element
// Common
id?:int
type?:layer_element_type
// Background Element Type
sprite_index?:sprite
image_index?:int
xscale?:number
yscale?:number
htiled?:bool
vtiled?:bool
stretch?:bool
visible?:bool
blendColour?:int
blendAlpha?:number
image_speed?:number
speed_type?:sprite_speed_type
name?:string
// Instance Element Type
inst_id?:instance
// Sprite Element Type
sprite_index?:sprite
image_index?:int
x?:number
y?:number
image_xscale?:number
image_yscale?:number
image_angle?:number
image_alpha?:number
image_blend?:int
image_speed?:number
speed_type?:sprite_speed_type
name?:string
// Tile Map Element Type
x?:number
y?:number
tileset_index?:tileset
data_mask?:int
tiles?:Array<int>
width?:int
height?:int
name?:string
// Particle System Element Type
ps?:particle
x?:number
y?:number
angle?:number
xscale?:number
yscale?:number
blend?:int
alpha?:number
name?:string
// Tile Element Type
visible?:bool
sprite_index?:sprite
x?:number
y?:number
width?:int
height?:int
image_xscale?:number
image_yscale?:number
image_angle?:number
image_blend?:int
image_alpha?:number
xo?:number
yo?:number
// Sequence Element Type
x?:number
y?:number
image_xscale?:number
image_yscale?:number
image_angle?:number
image_alpha?:number
image_blend?:int
image_speed?:number
speedType?:sprite_speed_type
seq_id?:sequence
name?:string
head_position?:number

??particle_system_info
name?:string
xorigin?:number
yorigin?:number
global_space?:bool
oldtonew?:bool
emitters?:Array<particle_emitter_info>

??particle_emitter_info
ind?:particle_emitter
name?:string
mode?:particle_mode
enabled?:bool
number?:number
relative?:bool
xmin?:number
xmax?:number
ymin?:number
ymax?:number
distribution?:particle_distribution
shape?:particle_shape
parttype?:particle_info
delay_min?:number
delay_max?:number
delay_unit?:time_source_units
interval_min?:number
interval_max?:number
interval_unit?:time_source_units

??particle_info
ind?:particle
// Shape / Sprite
sprite?:sprite
frame?:int
animate?:bool
stretch?:bool
random?:bool
shape?:particle_shape
// Size
size_xmin?:number
size_ymin?:number
size_xmax?:number
size_ymax?:number
size_xincr?:number
size_yincr?:number
size_xwiggle?:number
size_ywiggle?:number
// Scale
xscale?:number
yscale?:number
// Life
life_min?:int
life_max?:int
// Secondary Particles
death_type?:particle
death_number?:int
step_type?:particle
step_number?:int
// Speed
speed_min?:number
speed_max?:number
speed_incr?:number
speed_wiggle?:number
// Direction
dir_min?:int
dir_max?:int
dir_incr?:number
dir_wiggle?:number
// Gravity
grav_amount?:number
grav_dir?:int
// Orientation
ang_min?:int
ang_max?:int
ang_incr?:number
ang_wiggle?:number
ang_relative?:bool
// Color & Alpha
color1?:int
color2?:int
color3?:int
alpha1?:number
alpha2?:number
alpha3?:number
additive?:bool

??physics_hitpoint
instance?:instance
hitpointX?:number
hitpointY?:number
normalX?:number
normalY?:number
fraction?:number

??vertex_format_info
stride?:int
num_elements?:int
elements?:Array<vertex_format_element>

??vertex_format_element
usage?:vertex_usage
type?:vertex_type
size?:int
offset?:int

??tileset_info
width?:int
height?:int
texture?:texture
tile_width?:int
tile_height?:int
tile_horizontal_separator?:int
tile_vertical_separator?:int
tile_columns?:int
tile_count?:int
frame_count?:int
frame_length_ms?:int
frames?:struct

??audio_effect_type_enum
Bitcrusher?:audio_effect_type
Delay?:audio_effect_type
Gain?:audio_effect_type
HPF2?:audio_effect_type
LPF2?:audio_effect_type
Reverb1?:audio_effect_type
Tremolo?:audio_effect_type
PeakEQ?:audio_effect_type
HiShelf?:audio_effect_type
LoShelf?:audio_effect_type
EQ?:audio_effect_type
Compressor?:audio_effect_type

??audio_lfo_type_enum
InvSawtooth?:audio_lfo_type
Sawtooth?:audio_lfo_type
Sine?:audio_lfo_type
Square?:audio_lfo_type
Triangle?:audio_lfo_type

??flexpanel_data
name?:string
data?:struct
nodes?:flexpanel_data[]
width?:string|number
height?:string|number
minWidth?:string|number
maxWidth?:string|number
minHeight?:string|number
maxHeight?:string|number
left?:string|number
right?:string|number
top?:string|number
bottom?:string|number
alignContent?:string
alignItems?:string
alignSelf?:string
aspectRatio?:number
display?:string
flex?:number
flexGrow?:number
flexShrink?:number
flexBasis?:string|number
flexDirection?:string
flexWrap?:string
justifyContent?:string
direction?:string
gap?:number
gapRow?:number
gapColumn?:number
margin?:string|number
marginInline?:string|number
marginLeft?:string|number
marginRight?:string|number
marginTop?:string|number
marginBottom?:string|number
marginStart?:string|number
marginEnd?:string|number
marginHorizontal?:string|number
marginVertical?:string|number
padding?:string|number
paddingLeft?:string|number
paddingRight?:string|number
paddingTop?:string|number
paddingBottom?:string|number
paddingStart?:string|number
paddingEnd?:string|number
paddingHorizontal?:string|number
paddingVertical?:string|number
border?:string|number
borderLeft?:string|number
borderRight?:string|number
borderTop?:string|number
borderBottom?:string|number
borderStart?:string|number
borderEnd?:string|number
borderHorizontal?:string|number
borderVertical?:string|number
start?:string|number
end?:string|number
horizontal?:string|number
vertical?:string|number
position?:string
positionType?:string

??flexpanel_unit_value
unit?:flexpanel_unit_type
value?:number

??flexpanel_unit_enum
point?:flexpanel_unit_type
percent?:flexpanel_unit_type
auto?:flexpanel_unit_type

flexpanel_unit#:flexpanel_unit_enum

??flexpanel_direction_enum
inherit?:flexpanel_direction_type
LTR?:flexpanel_direction_type
RTL?:flexpanel_direction_type

flexpanel_direction#:flexpanel_direction_enum

??flexpanel_layout
left?:number
top?:number
width?:number
height?:number
bottom?:number
right?:number
hadOverflow?:bool
direction?:flexpanel_direction_type
paddingLeft?:number
paddingRight?:number
paddingTop?:number
paddingBottom?:number
marginLeft?:number
marginRight?:number
marginTop?:number
marginBottom?:number

??flexpanel_justify_enum
start?:flexpanel_justify_type
flex_end?:flexpanel_justify_type
center?:flexpanel_justify_type
space_between?:flexpanel_justify_type
space_around?:flexpanel_justify_type
space_evenly?:flexpanel_justify_type

flexpanel_justify#:flexpanel_justify_enum

??flexpanel_align_enum
stretch?:flexpanel_align_type
flex_start?:flexpanel_align_type
flex_end?:flexpanel_align_type
center?:flexpanel_align_type
baseline?:flexpanel_align_type

flexpanel_align#:flexpanel_align_enum

??flexpanel_display_enum
flex?:flexpanel_display_type
none?:flexpanel_display_type

flexpanel_display#:flexpanel_display_enum

??flexpanel_flex_direction_enum
column?:flexpanel_flex_direction_type
row?:flexpanel_flex_direction_type
column_reverse?:flexpanel_flex_direction_type
row_reverse?:flexpanel_flex_direction_type

flexpanel_flex_direction#:flexpanel_flex_direction_enum

??flexpanel_wrap_enum
no_wrap?:flexpanel_wrap_type
wrap?:flexpanel_wrap_type
reverse?:flexpanel_wrap_type

flexpanel_wrap#:flexpanel_wrap_enum

??flexpanel_gutter_enum
all_gutters?:flexpanel_gutter_type
row?:flexpanel_gutter_type
column?:flexpanel_gutter_type

flexpanel_gutter#:flexpanel_gutter_enum

??flexpanel_edge_enum
left?:flexpanel_edge_type
top?:flexpanel_edge_type
right?:flexpanel_edge_type
bottom?:flexpanel_edge_type
start?:flexpanel_edge_type
end?:flexpanel_edge_type
horizontal?:flexpanel_edge_type
vertical?:flexpanel_edge_type
all_edges?:flexpanel_edge_type

flexpanel_edge#:flexpanel_edge_enum

??flexpanel_position_enum
relative?:flexpanel_position
absolute?:flexpanel_position
static?:flexpanel_position

flexpanel_position_type#:flexpanel_position_enum

??colspace_enum
room?:colspace_type
ui_view?:colspace_type
ui_display?:colspace_type
colspace_all?:colspace_type

colspace#:colspace_enum

??texgroup_info
sprites?:struct

layer_type_unknown#:layer_type
layer_type_room#:layer_type
layer_type_ui_viewports#:layer_type
layer_type_ui_display#:layer_type