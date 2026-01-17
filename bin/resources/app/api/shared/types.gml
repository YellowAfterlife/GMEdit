typedef external_call_type;
typedef external_value_type;
typedef external_function;

// or "feathername", to map Feather's type names to GMEdit ones
fe_name int = constant.colour;

//
typedef ds_type : minus1able;
typedef ds_map : minus1able;
fe_name ds_map = id.dsmap;
typedef ds_list : minus1able;
fe_name ds_list = id.dslist;
typedef ds_stack : minus1able;
fe_name ds_stack = id.dsstack;
typedef ds_queue : minus1able;
fe_name ds_queue = id.dsqueue;
typedef ds_grid : minus1able;
fe_name ds_grid = id.dsgrid;
typedef ds_priority : minus1able;
fe_name ds_priority = id.priority;

// e.g. CustomKeyArray<object, bool> allows arr[obj_some]
typedef ckarray;
typedef CustomKeyArray;

typedef ckstruct;
typedef CustomKeyStruct;

// tuple<int, string> accepts [1, "2"]
typedef tuple;
// enum_tuple<my_enum> uses values and metadata from my_enum
typedef enum_tuple;

// specified_map<a:int, b:string, void> allows only map[?"a"] and map[?"b"]
typedef specified_map;

// any_fields_of<Struct> is a struct containing some/all fields of Struct
typedef any_fields_of;
// params_of<T> extracts template parameters from T, so (params_of<T<int, string, undefined>>) will allow (int, string, undefined)
typedef params_of;
// params_of_nl<T> is like above but without the last parameter (useful for extracting types of arguments from function<>)
typedef params_of_nl;
// last_param_of<T> extracts only the last parameter (useful for extracting return type from function<>)
typedef last_param_of;

// GMEdit will auto-pick these for async_load based on event name
typedef async_load_http = specified_map<
	id:int,
	status:int,
	result:string,
	url:string,
	http_status:int,
	contentLength:int,
	sizeDownloaded:int,
	void
>;

typedef async_load_audio_playback = specified_map<
	queue_id:sound_play_queue,
	buffer_id:buffer,
	queue_shutdown:int,
	void
>;

typedef async_load_audio_recording = specified_map<
	channel_index:int,
	buffer_id:buffer,
	data_len:int,
	void
>;

typedef async_load_cloud = specified_map<
	id:int,
	status:int,
	description:string,
	resultString:string,
	errorString:string,
	void
>;

typedef async_load_dialog = specified_map<
	id:int,
	status:int,
	// get_string
	result:string,
	// get_integer
	value:int,
	// get_login:
	username:string,
	password:string,
	//
	void
>;

typedef async_load_network = specified_map<
	id:network_socket,
	type:network_async_id,
	ip:string,
	port:int,
	socket:network_socket, // in connect/disconnect
	succeeded:bool, // in non-blocking connect
	buffer:buffer, // in data
	size:int, // in data
	void
>;

typedef async_load_image = specified_map<
	filename:string,
	id:sprite,
	status:int,
	void
>;

typedef async_save_load_id : minus1able;
typedef async_load_save_load = specified_map<
	id:async_save_load_id,
	status:bool,
	void
>;

// todo: more async events

//{ Asset types
typedef asset : minus1able, simplename

feathername: asset.gm*
typedef sprite : asset, simplename

feathername: asset.gm*
typedef sound : asset, simplename

feathername: asset.gm*
typedef path : asset, simplename

feathername: asset.gm*
typedef script : asset, simplename

feathername: asset.gm*
typedef shader : asset, simplename

feathername: asset.gm*
typedef font : asset, simplename

feathername: asset.gm*
typedef timeline : asset, simplename

feathername: asset.gm*
typedef object : asset, simplename

feathername: asset.gm*
typedef room : asset, simplename

feathername: asset.gm*
typedef audio_group : asset, simplename
//}

//{ Types that generally have some data attached to them
// Feather type is Real
typedef datetime : simplename

// Feather type matches
typedef pointer : simplename

// Feather type is Real
typedef mp_grid : minus1able

feathername: id.*
typedef buffer : minus1able, simplename

feathername: id.*
typedef surface : minus1able, simplename

feathername: pointer.*
typedef texture : minus1able, simplename

feathername: id.*
typedef audio_emitter : minus1able

feathername: id.sound
typedef sound_instance : minus1able

feathername: id.AudioSyncGroup
typedef sound_sync_group : minus1able

// Feather type is Real
typedef sound_play_queue : minus1able

// Feather type is Real
typedef html_clickable : minus1able

// Feather type is Real
typedef html_clickable_tpe

// Feather type is Any
typedef texture_group

feathername: Id.TextFile
typedef file_handle : minus1able

feathername: Id.BinaryFile
typedef binary_file_handle : minus1able

feathername: Id.ParticleType
typedef particle : minus1able, simplename

feathername: Id.ParticleSystem
typedef particle_system : minus1able

feathername: Id.ParticleEmitter
typedef particle_emitter : minus1able

// Feather type is Real
typedef virtual_key

feathername: Id.PhysicsIndex
typedef physics_fixture : minus1able

// Feather type is Real
typedef physics_joint : minus1able

// Feather type is Real
typedef physics_particle : minus1able

feathername: Id.PhysicsParticleGroup
typedef physics_particle_group : minus1able

feathername: Id.Socket
typedef network_socket : minus1able

// Feather type is Real
typedef network_server : minus1able

feathername: id.*
typedef vertex_buffer : minus1able

feathername: id.*
typedef vertex_format : minus1able

feathername: Id.Sampler
typedef shader_sampler : minus1able

feathername: Id.Uniform
typedef shader_uniform : minus1able

typedef steam_id
typedef steam_ugc
typedef steam_ugc_query
//}

// Things inheriting from uncompareable shouldn't be compared to each other
typedef uncompareable

//{ Dumb types, only used as function arguments, can't be created
// If something doesn't have a feathername/comment next to it,
// I didn't get around to it - check yourself against GmlSpec.xml and submit a PR
typedef timezone_type : uncompareable

feathername: Constant.GameSpeed
typedef gamespeed_type : uncompareable

feathername: Constant.PathAction
typedef path_endaction : uncompareable

feathername: Constant.EventType
typedef event_type : uncompareable

feathername: Constant.EventNumber
typedef event_number : uncompareable

//
typedef mouse_button : uncompareable

feathername: Constant.BBoxMode
typedef bbox_mode : uncompareable

feathername: Constant.CollisionMask
typedef bbox_kind : uncompareable

feathername: Constant.HAlign
typedef horizontal_alignment : uncompareable

feathername: Constant.VAlign
typedef vertical_alignment : uncompareable

feathername: Constant.PrimitiveType
typedef primitive_type : uncompareable

feathername: Constant.BlendMode
typedef blendmode : uncompareable

feathername: Constant.BlendModeFactor
typedef blendmode_ext : uncompareable

//
typedef texture_mip_filter : uncompareable

//
typedef texture_mip_state : uncompareable


typedef audio_falloff_model : uncompareable


typedef audio_sound_channel : uncompareable


typedef display_orientation : uncompareable


typedef window_cursor : uncompareable

feathername: Constant.BufferType
typedef buffer_kind : uncompareable // buffer_grow, etc

feathername: Constant.BufferDataType
typedef buffer_type : uncompareable // buffer_s8, etc

// magic - picks up the type from the nearby buffer_type argument
typedef buffer_auto_type


typedef sprite_speed_type : uncompareable

feathername: Constant.AssetType
typedef asset_type : uncompareable


typedef file_attribute : int


typedef particle_shape : uncompareable


typedef particle_distribution : uncompareable


typedef particle_region_shape : uncompareable


typedef effect_kind : uncompareable


typedef matrix_type : uncompareable

feathername: Constant.OperatingSystem
typedef os_type : uncompareable

feathername: Constant.BrowserType
typedef browser_type : uncompareable

feathername: Constant.DeviceType
typedef device_type : uncompareable


typedef openfeint_challenge : uncompareable


typedef achievement_leaderboard_filter : uncompareable


typedef achievement_challenge_type : uncompareable


typedef achievement_async_id : uncompareable


typedef achievement_show_type : uncompareable


typedef iap_system_status : uncompareable


typedef iap_order_status : uncompareable


typedef iap_async_id : uncompareable


typedef iap_async_storeload : uncompareable


typedef gamepad_button : uncompareable
fe_name gamepad_button = constant.gamepadbutton
typedef gamepad_axis : uncompareable
fe_name gamepad_axis = constant.gamepadaxis


typedef physics_debug_flag : int


typedef physics_joint_value


typedef physics_particle_flag : int


typedef physics_particle_data_flag : int


typedef physics_particle_group_flag : int

feathername: Constant.SocketType
typedef network_type : uncompareable

feathername: Constant.NetworkConfig
typedef network_config : uncompareable

feathername: Constant.NetworkType
typedef network_async_id : uncompareable

feathername: Constant.SeekOffset
typedef buffer_seek_base : uncompareable


typedef steam_overlay_page : uncompareable


typedef steam_leaderboard_sort_type : uncompareable


typedef steam_leaderboard_display_type : uncompareable


typedef steam_ugc_type : uncompareable


typedef steam_ugc_async_result : uncompareable


typedef steam_ugc_visibility : uncompareable


typedef steam_ugc_query_type : uncompareable


typedef steam_ugc_query_list_type : uncompareable


typedef steam_ugc_query_match_type : uncompareable


typedef steam_ugc_query_sort_order : uncompareable

feathername: Constant.VertexType
typedef vertex_type : uncompareable

feathername: Constant.VertexUsage
typedef vertex_usage : uncompareable

feathername: Constant.LayerElementType
typedef layer_element_type : uncompareable
//}