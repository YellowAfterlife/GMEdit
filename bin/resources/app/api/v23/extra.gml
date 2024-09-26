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
glyphs?:font_info_glyph[]
sdfEnabled?:bool
sdfSpread?:number
effectsEnabled?:number
effectParams?:font_effect_params

??font_info_glyph
char?:int
x?:number
y?:number
w?:number
h?:number
shift?:number
offset?:number
kerning?:int[]

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
messages?:sprite_message[]
frame_info?:sprite_frame_info[]|undefined
frame_speed?:number
frame_type?:sprite_speed_type
frames?:sprite_frame[]
num_atlas:int
atlas_texture?:texture[]
premultiplied?:bool
animation_names?:string[]
skin_names?:string[]
bones?:sprite_spine_bone[]
slots?:sprite_spine_slot[]

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
attachments?:string[]

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
instances?:room_info_instance[]
layers?:room_info_layer[]
views?:room_info_view[]

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
elements?:room_info_layer_element[]

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
tiles?:int[]
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