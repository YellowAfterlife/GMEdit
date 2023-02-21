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
