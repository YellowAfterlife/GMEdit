// Context: it should be possible to override an auto-detected variable signature with a @hint.
function v_hint_override_c() constructor {
    static func = function() {}
}
/// @hint v_hint_override_c:func(val:number)->int
function v_hint_override() {
    let c = new v_hint_override_c();
    c.func(); ///want_warn "Not enough arguments"
}