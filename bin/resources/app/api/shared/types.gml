typedef external_call_type;
typedef external_value_type;
typedef external_function;

//
typedef ds_type : minus1able;
typedef ds_map : minus1able;
typedef ds_list : minus1able;
typedef ds_stack : minus1able;
typedef ds_queue : minus1able;
typedef ds_grid : minus1able;
typedef ds_priority : minus1able;

// e.g. CustomKeyArray<object, bool> allows arr[obj_some]
typedef ckarray;
typedef CustomKeyArray;

// tuple<int, string> accepts [1, "2"]
typedef tuple;

// specified_map<a:int, b:string, void> allows only map[?"a"] and map[?"b"]
typedef specified_map;

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

// Asset types
typedef asset : minus1able;
typedef sprite : asset;
typedef sound : asset;
typedef path : asset;
typedef script : asset;
typedef shader : asset;
typedef font : asset;
typedef timeline : asset;
typedef object : asset;
typedef room : asset;
typedef audio_group : asset;

// Types that generally have some data attached to them
typedef datetime
typedef pointer
typedef mp_grid : minus1able
typedef buffer : minus1able
typedef surface : minus1able
typedef texture : minus1able
typedef audio_emitter : minus1able
typedef sound_instance : minus1able
typedef sound_sync_group : minus1able
typedef sound_play_queue : minus1able
typedef html_clickable : minus1able
typedef html_clickable_tpe
typedef texture_group
typedef file_handle : minus1able
typedef binary_file_handle : minus1able
typedef particle : minus1able
typedef particle_system : minus1able
typedef particle_emitter : minus1able
typedef virtual_key
typedef physics_fixture : minus1able
typedef physics_joint : minus1able
typedef physics_particle : minus1able
typedef physics_particle_group : minus1able
typedef network_socket : minus1able
typedef network_server : minus1able
typedef vertex_buffer : minus1able
typedef steam_id
typedef steam_ugc
typedef steam_ugc_query
typedef shader_sampler : minus1able
typedef shader_uniform : minus1able
typedef vertex_format : minus1able
typedef vertex_buffer : minus1able

// Things inheriting from uncompareable shouldn't be compared to each other
typedef uncompareable

// Dumb types, only used as function arguments, can't be created
typedef timezone_type : uncompareable
typedef gamespeed_type : uncompareable
typedef path_endaction : uncompareable
typedef event_type : uncompareable
typedef event_number : uncompareable
typedef mouse_button : uncompareable
typedef bbox_mode : uncompareable
typedef bbox_kind : uncompareable
typedef horizontal_alignment : uncompareable
typedef vertical_alignment : uncompareable
typedef primitive_type : uncompareable
typedef blendmode : uncompareable
typedef blendmode_ext : uncompareable
typedef texture_mip_filter : uncompareable
typedef texture_mip_state : uncompareable
typedef audio_falloff_model : uncompareable
typedef audio_sound_channel : uncompareable
typedef display_orientation : uncompareable
typedef window_cursor : uncompareable
typedef buffer_kind : uncompareable//buffer_grow etc
typedef buffer_type : uncompareable //buffer_s8 etc
typedef sprite_speed_type : uncompareable
typedef asset_type : uncompareable
typedef buffer_auto_type // magic - picks up the type from the nearby buffer_type argument
typedef file_attribute : int
typedef particle_shape : uncompareable
typedef particle_distribution : uncompareable
typedef particle_region_shape : uncompareable
typedef effect_kind : uncompareable
typedef matrix_type : uncompareable
typedef os_type : uncompareable
typedef browser_type : uncompareable
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
typedef physics_debug_flag : int
typedef physics_joint_value
typedef physics_particle_flag : int
typedef physics_particle_data_flag : int
typedef physics_particle_group_flag : int
typedef network_type : uncompareable
typedef network_config : uncompareable
typedef network_async_id : uncompareable
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
typedef vertex_type : uncompareable
typedef vertex_usage : uncompareable
typedef layer_element_type : uncompareable