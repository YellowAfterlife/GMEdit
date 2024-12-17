//
feathername: Struct.WeakRef
typedef weak_reference : WeakRef;

feathername: Asset.GMSequence
typedef sequence : asset, simplename;

feathername: Asset.GMAnimCurve
typedef animcurve : asset, simplename;

feathername: Id.TimeSource
typedef time_source;

feathername: Constant.TimeSourceExpiryType
typedef time_source_expiry;

feathername: Constant.TimeSourceState
typedef time_source_state;

feathername: Constant.TimeSourceUnits
typedef time_source_units;

feathername: Pointer.View
typedef debug_view;

feathername: Pointer.Section
typedef debug_section;

feathername: Id.DbgRef
typedef debug_reference;

fe_name Exception = Struct.Exception;

feathername: Struct.FontInfo
typedef font_info : struct;

feathername: Struct.FontInfoGlyph
typedef font_info_glyph : struct;

feathername: Struct.FontEffectParams
typedef font_effect_params : struct;

typedef font_glyph_cache : struct;

typedef sprite_info : struct;

typedef sprite_message : struct;

typedef sprite_frame_info : struct;

typedef sprite_frame : struct;

typedef sprite_spine_bone : struct;

typedef sprite_spine_slot : struct;

feathername: Struct.NineSlice
typedef nineslice : struct, minus1able;

typedef nineslice_tile_index : uncompareable;

typedef nineslice_tile_mode : uncompareable;

typedef texture_group_status : uncompareable;

typedef room_info : struct;

typedef room_info_instance : struct;

typedef room_info_layer : struct;

typedef room_info_view : struct;

typedef room_info_layer_element : struct;

typedef async_load_image = specified_map<
	filename:string,
	id:sprite,
    http_status:int,
	status:sprite_add_ext_error,
	void
>;

typedef sprite_add_ext_error : int;

feathername: Asset.GMParticleSystem
typedef particle_asset : asset, simplename;

typedef particle_system_info : struct;

typedef particle_emitter_info : struct;

typedef particle_info : struct;

feathername: Constant.ParticleEmitterMode
typedef particle_mode : uncompareable;

feathername: Constant.StencilOp
typedef gpu_stencilop : uncompareable;

feathername: Constant.BlendModeEquation
typedef blendmode_equation : uncompareable;

feathername: Constant.SurfaceFormatType
typedef surface_format : uncompareable;

feathername: Constant.VideoStatus
typedef video_status : uncompareable;

feathername: Constant.VideoFormat
typedef video_format : uncompareable;

feathername: Struct.Zip;
typedef zip_object;

typedef buffer_write_error : int;

typedef physics_hitpoint : struct;

feathername: Constant.SendOption
typedef network_send_option : uncompareable;

feathername: Constant.NetworkConnectType
typedef network_connect_type : uncompareable;

feathername: Struct.VertexFormatInfo
typedef vertex_format_info : struct;

typedef vertex_format_element: struct;

feathername: Struct.SkeletonSkin
typedef skeleton_skin : struct;

feathername: Struct.TileSetInfo
typedef tileset_info;

feathername: Struct.SpriteInfo;
typedef sprite_info;

feathername: Id.TextElement
typedef layer_text : layer_element

feathername: Struct.SequenceInstance
typedef sequence_instance : SequenceInstance;

feathername: Struct.Sequence
typedef sequence_object : Sequence, minus1able;

feathername: Struct.Track
typedef sequence_track : Track;

feathername: Struct.Keyframe
typedef sequence_keyframe : Keyframe;

feathername: Struct.KeyframeData
typedef sequence_keyframe_data : KeyChannel;

typedef GraphicTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_graphic : GraphicTrack;

typedef SequenceTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_sequence : SequenceTrack;

typedef AudioTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_audio : AudioTrack;

typedef SpriteTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_sprite : SpriteTrack;

typedef BoolTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_bool : BoolTrack;

typedef StringTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_string : StringTrack;

typedef ColourTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_colour : ColourTrack;

typedef ColorTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_color : ColorTrack;

typedef RealTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_real : RealTrack;

typedef InstanceTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_instance : InstanceTrack;

typedef TextTrack : sequence_keyframe_data;
typedef sequence_keyframe_data_text : TextTrack;

typedef MessageEvent : sequence_keyframe_data;
typedef sequence_keyframe_data_message : MessageEvent;

typedef Moment : sequence_keyframe_data;
typedef sequence_keyframe_data_moment : Moment;

feathername: Struct.AnimCurve
typedef animcurve_struct : AnimCurve;

feathername: Struct.AnimCurveChannel
typedef animcurve_channel : AnimCurveChannel;

feathername: Struct.AnimCurvePoint
typedef animcurve_point : AnimCurvePoint;

typedef sequence_active_track : TrackEvalNode;

feathername: Constant.SequenceTrackType
typedef sequence_track_type : uncompareable;

feathername: Constant.SequencePlay
typedef sequence_play_mode : uncompareable;

feathername: Constant.SequenceDirection
typedef sequence_direction : uncompareable;

typedef sequence_interpolation : uncompareable;

feathername: Constant.SequenceAudioKey
typedef sequence_audio_mode : uncompareable;

feathername: Constant.TextAlign
typedef text_horizontal_alignment : uncompareable;

feathername: Constant.TextAlign
typedef text_vertical_alignment : uncompareable;

feathername: Constant.AnimCurveInterpolationType
typedef animcurve_interpolation : uncompareable;

feathername: Struct.Fx
typedef fx_struct : minus1able;

feathername: Struct.GCStats
typedef gc_stats : GCStats;

feathername: Struct.AudioBus
typedef audio_bus : AudioBus;

feathername: Struct.AudioEffect
typedef audio_effect : AudioEffect : struct;

feathername: Enum.AudioEffectType
typedef audio_effect_type : uncompareable;

feathername: Enum.AudioLFOType
typedef audio_lfo_type : uncompareable;

feathername: Pointer.FlexpanelNode
typedef flexpanel_node;

typedef flexpanel_data : struct;

typedef flexpanel_unit_value : struct;

feathername: Enum.flexpanel_unit_type
typedef flexpanel_unit_type : uncompareable;

feathername: Enum.flexpanel_direction
typedef flexpanel_direction_type : string;

typedef flexpanel_position : struct;

feathername: Enum.flexpanel_justify
typedef flexpanel_justify_type : string;

feathername: Enum.flexpanel_align
typedef flexpanel_align_type : string;

feathername: Enum.flexpanel_display
typedef flexpanel_display_type : string;

feathername: Enum.flexpanel_flex_direction
typedef flexpanel_flex_direction_type : string;

feathername: Enum.flexpanel_wrap
typedef flexpanel_wrap_type : string;

feathername: Enum.flexpanel_gutter
typedef flexpanel_gutter_type : string;

feathername: Enum.flexpanel_edge
typedef flexpanel_edge_type : string;

feathername: Enum.flexpanel_position_type
typedef flexpanel_position : string;

fe_name mp_grid = Id.MpGrid;