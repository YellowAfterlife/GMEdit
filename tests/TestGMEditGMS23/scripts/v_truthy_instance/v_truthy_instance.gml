// Context: instances should be cast-able to boolean
// when the result is a boolean (&&,||,^^,!)
// or discarded (ifs, loops)
function v_truthy_instance() {
    let a = instance_nearest(0, 0, obj_test);
    let b = instance_nearest(0, 0, obj_test) /*#as object*/;
    if (a) {}
    if (!a) {}
    if (a && b) {}
    if (a || b) {}
    if (a ^^ b) {}
    while (a) break;
    for (;a;) break;
    do {break;} until (a);
    let i = a + 1; ///want_warn "to number"
    if (a < 0) {} ///want_warn "to number" - unsafe as of 2.3 due to struct-refs
}