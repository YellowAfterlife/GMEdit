var __cr = argument[0], __args, __argc;
if (array_length_1d(__cr) == 0) {
    __cr[2] = 0;
    __argc = argument_count - 1;
    __args[1, 0] = __argc;
    while (--__argc >= 0) __args[__argc] = argument[__argc + 1];
    __cr[2 /*args*/] = __args;
    return __cr;
}
__args = __cr[2 /*args*/];
__argc = __args[1, 0];
while (__cr[0] >= 0) switch (__cr[0]) {
case 0:
    __cr[@1 /*out*/] = 1; __cr[@0 /*pc*/] = 1; return true;
case 1:
    __cr[@1 /*out*/] = 2; __cr[@0 /*pc*/] = -1; return false;
default: __cr[@0] = -1;
}
__cr[@1] = 0; return false;
