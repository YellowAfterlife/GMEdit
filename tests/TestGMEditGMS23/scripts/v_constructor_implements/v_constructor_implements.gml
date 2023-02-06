/// @interface {IMovable}
function v_constructor_implements_movable() {
    xspeed = 0;
    yspeed = 0;
}

/// @implements {IMovable}
function v_constructor_implements() constructor {
    // after saving, writing `self.` here would now bring up `xspeed` and `yspeed`.
    v_constructor_implements_movable();
    zero = 0;
    one = xspeed;
    two = zspeed; ///want_warn 
    
    Step = function() {
        xspeed = 2;
        //zspeed = 3; ///want_warn
    }
}