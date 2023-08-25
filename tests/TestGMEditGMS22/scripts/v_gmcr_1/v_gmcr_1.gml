/// v_gmcr_1(ctx, array)
var l_ctx = argument[0];
if (!is_array(l_ctx)) {
    l_ctx = array_create(6);
    var l_argc = argument_count - 1;
    var l_args = array_create(l_argc);
    while (--l_argc >= 0) l_args[@l_argc] = argument[l_argc + 1];
    l_ctx[2/* args */] = l_args;
    return l_ctx;
}
var l_args = l_ctx[2/* args */];
while (true) switch (l_ctx[1/* label */]) {
case 0/* [L1,c1] begin */:
    l_ctx[@3/* arr */] = l_args[0];
    l_ctx[@4/* len */] = array_length_1d(l_ctx[3/* arr */]);
    l_ctx[@5/* i */] = 0;
case 1/* [L5,c1] check for */:
    if (l_ctx[5/* i */] >= l_ctx[4/* len */]) { l_ctx[@1/* label */] = 4; continue; }
    l_ctx[@0/* yield */] = array_wget(l_ctx[3/* arr */], l_ctx[5/* i */]); l_ctx[@1/* label */] = 2; return true;
case 2/* [L6,c5] post yield, [L5,c1] post for */:
    l_ctx[@5/* i */]++;
    l_ctx[@1/* label */] = 1; continue;
default/* [L5,c1] end for, [L7,c2] end */: l_ctx[@0/* yield */] = 0; return false;
}

/*//!#gmcr
/// v_gmcr_1(array)
#gmcr
var arr = argument0;
var len = array_length_1d(arr);
for (var i = 0; i < len; i++) {
    yield arr[i];
}
//!#gmcr*/
