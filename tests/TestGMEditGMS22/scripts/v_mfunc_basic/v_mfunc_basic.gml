//!#mfunc nameof {"args":["s"],"order":[[1,0]]}
#macro nameof_mf0  //
#macro nameof_mf1 //
//!#mfunc validate {"args":["s"],"order":[0,0]}
#macro validate_mf0  if (
#macro validate_mf1  == undefined) show_debug_message(nameof(
#macro validate_mf2 ) + " is undefined.");

var me = "me";
show_debug_message(nameof_mf0 "me" nameof_mf1);
//validate(me); // <- bug!