/// @param ...funcs
function v_arrow_funcs() { 
	var blankBlock = function() /*=>*/ {};
	var blankExpr = function() /*=>*/ {return 0};
	var oneBlock = function(a) /*=>*/ { show_debug_message(a) };
	var oneExpr = function(a) /*=>*/ {return -a};
	//*
	var arr = [2, 1, 3];
	array_sort(arr, function(a, b) /*=>*/ {return a - b});
	//*
	var hell = function() /*=>*/ {return [
		function() /*=>*/ {return 1},
		function() /*=>*/ {return 2},
		function() /*=>*/ {return 3}
	]};
	//var a1 = (a,b) => a + b;*/
}