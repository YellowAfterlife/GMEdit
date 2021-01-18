typedef dll_t;
typedef ty_t;
typedef external_function;

//
typedef ds_type;
typedef ds_map;
typedef ds_list;
typedef ds_stack;
typedef ds_queue;
typedef ds_grid;
typedef ds_priority;

// Asset types
typedef asset;
typedef sprite : asset;
typedef sound : asset;
typedef path : asset;
typedef script : asset;
typedef shader : asset;
typedef font : asset;
typedef timeline : asset;
typedef object : asset;
typedef room : asset;

// Types that generally have some data attached to them
typedef datetime
typedef pointer
typedef mp_grid
typedef buffer
typedef surface
typedef texture
typedef audio_emitter
typedef sound_instance
typedef sound_sync_group
typedef sound_play_queue
typedef html_clickable
typedef html_clickable_tpe
typedef texture_group
typedef file_handle
typedef binary_file_handle
typedef particle
typedef particle_system
typedef particle_emitter
typedef virtual_key
typedef physics_fixture
typedef physics_joint
typedef physics_particle
typedef physics_particle_group
typedef network_socket
typedef network_server
typedef vertex_buffer
typedef steam_id
typedef steam_ugc
typedef steam_ugc_query
typedef shader_sampler
typedef shader_uniform
typedef vertex_format
typedef vertex_buffer

// Dumb types, only used as function arguments, can't be created
typedef timezone_type
typedef gamespeed_type
typedef path_endaction
typedef event_type
typedef event_number
typedef mouse_button
typedef bbox_mode
typedef bbox_kind
typedef horizontal_alignment
typedef vertical_alignment
typedef primitive_type
typedef blendmode
typedef blendmode_ext
typedef texture_mip_filter
typedef texture_mip_state
typedef audio_falloff_model
typedef audio_sound_channel
typedef display_orientation
typedef window_cursor
typedef buffer_kind //buffer_grow etc
typedef buffer_type //buffer_s8 etc
typedef sprite_speed_type
typedef asset_type
typedef file_attribute : int
typedef particle_shape
typedef particle_distribution
typedef particle_region_shape
typedef effect_kind
typedef matrix_type
typedef os_type
typedef browser_type
typedef device_type
typedef openfeint_challenge
typedef achievement_leaderboard_filter
typedef achievement_challenge_type
typedef achievement_async_id
typedef achievement_show_type
typedef iap_system_status
typedef iap_order_status
typedef iap_async_id
typedef iap_async_storeload
typedef gamepad_button
typedef physics_debug_flag : int
typedef physics_joint_value
typedef physics_particle_flag : int
typedef physics_particle_data_flag : int
typedef physics_particle_group_flag : int
typedef network_type
typedef network_config
typedef network_async_id
typedef buffer_seek_base
typedef steam_overlay_page
typedef steam_leaderboard_sort_type
typedef steam_leaderboard_display_type
typedef steam_ugc_type
typedef steam_ugc_async_result
typedef steam_ugc_visibility
typedef steam_ugc_query_type
typedef steam_ugc_query_list_type
typedef steam_ugc_query_match_type
typedef steam_ugc_query_sort_order
typedef vertex_type
typedef vertex_usage
typedef layer_element_type