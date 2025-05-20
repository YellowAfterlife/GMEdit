var myarray = [1,2,3];
var iter = v_gmcr_1(0, myarray);
while (v_gmcr_1(iter)) {
    show_message(iter[0]);
}
exit;
var b/*:bool*/;
let cr = v_gmcr_1(0, myarray);
cr = v_gmcr_1(undefined);
cr = v_gmcr_1(cr); ///want_warn
b = v_gmcr_1(cr);
b = v_gmcr_1(0, myarray); ///want_warn