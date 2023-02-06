// in GM2022+, we have out-of-box color literals - this should remain untouched.
function v_color_literal() {
	var a = #123456;
	var c0ffee = 0;
	var grid = ds_grid_create(1, 1);
	grid[#c0ffee, 0] = 1;
}