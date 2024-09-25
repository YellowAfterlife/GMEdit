//
feathername: Struct.WeakRef
typedef weak_reference;

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

feathername: Constant.BlendModeEquation
typedef blendmode_equation : uncompareable;

feathername: Constant.SurfaceFormatType
typedef surface_format : uncompareable;

feathername: Constant.VideoStatus
typedef video_status : uncompareable;

feathername: Constant.VideoFormat
typedef video_format : uncompareable;

feathername: Struct.SpriteInfo;
typedef sprite_info;

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

feathername: Constant.SequenceTextKey
typedef text_horizontal_alignment : uncompareable

feathername: Constant.SequenceTextKey
typedef text_vertical_alignment : uncompareable

feathername: Constant.AnimCurveInterpolationType
typedef animcurve_interpolation : uncompareable

fe_name mp_grid = Id.MpGrid;