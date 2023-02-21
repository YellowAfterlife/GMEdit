function lint_audio_play_sound_ext() {
	var snd/*:sound*/ = -1;
	audio_play_sound_ext({ sound: snd });
	audio_play_sound_ext({ sound: snd, extra_var: 1 }); ///want_warn
	audio_play_sound_ext({
		sound: snd,
		position: {
			x: 0, y: 0, z: 0,
			falloff_ref: 0,
			falloff_max: 0,
			falloff_factor: 0,
		}
	});
	audio_play_sound_ext({
		sound: snd,
		position: {
			x: 0, y: 0, z: 0,
			falloff_ref: 0,
			falloff_max: 0,
			//falloff_factor: 0,
		}
	}); ///want_warn
	audio_play_sound_ext({ }); ///note: wrong, but I'm not making a new type just for this
}