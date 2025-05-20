// Visual
feathername: id.*
typedef camera : simplename

//
typedef display_timing_method

feathername: Constant.ZFunction
typedef gpu_cmpfunc

feathername: Constant.CullMode
typedef gpu_cullmode

//
typedef draw_lighttype

//
typedef tilemap_data : int

feathername: Asset.GMTileSet
typedef tileset : asset, simplename;

// Layers!
feathername: id.*
typedef layer : simplename

// Any
typedef layer_element

feathername: Id.BackgroundElement
typedef layer_background : layer_element

feathername: Id.SpriteElement
typedef layer_sprite : layer_element

feathername: Id.TilemapElement
typedef layer_tilemap : layer_element

// not using this in GMEdit I think?
typedef layer_instance : layer_element

feathername: Id.TileElementId
typedef layer_tile_legacy : layer_element

feathername: Id.SequenceElement
typedef layer_sequence : layer_element

// Virtual Keyboard

typedef virtual_keyboard_type


typedef virtual_keyboard_return_key


typedef virtual_keyboard_autocapitalization

// misc.

typedef android_permission_state

feathername: id.gif
typedef gif : simplename
