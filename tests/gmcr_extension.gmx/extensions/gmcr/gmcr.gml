#define gmcr_init
// Generated at 2018-02-19 13:33:17 (203ms)

#define array_from_values
/// array_from_values(...values:T)->array<T>
var l_n=argument_count;
var l_r=array_create(l_n);
var l_i=0;
for(var l__g=l_n;l_i<l__g;l_i+=1){
	l_r[@l_i]=argument[l_i];
}
return l_r;

#define array_wget
/// array_wget(arr:array<T>, i:int)->T
var l_arr=argument[0],l_i=argument[1];
return l_arr[l_i];

#define array_aop
/// array_aop(w:array<dynamic>, i:int, o:GmlOp, v:dynamic)->dynamic
var l_w=argument[0],l_i=argument[1],l_o=argument[2],l_v=argument[3];
var l_r=l_w[l_i];
switch(l_o){
	case 0:l_r*=l_v;break;
	case 1:l_r/=l_v;break;
	case 2:l_r%=l_v;break;
	case 3:l_r=(l_r div l_v);break;
	case 16:l_r+=l_v;break;
	case 17:l_r-=l_v;break;
	case 32:l_r=l_r<<l_v;break;
	case 33:l_r=l_r>>l_v;break;
	case 48:l_r|=l_v;break;
	case 49:l_r&=l_v;break;
	case 50:l_r^=l_v;break;
	case 64:l_r=l_r==l_v;break;
	case 65:l_r=l_r!=l_v;break;
	case 66:l_r=l_r<l_v;break;
	case 67:l_r=l_r<=l_v;break;
	case 68:l_r=l_r>l_v;break;
	case 69:l_r=l_r>=l_v;break;
}
l_w[@l_i]=l_r;
return l_r;

#define array_prefix
/// array_prefix(w:array<dynamic>, i:int, o:GmlOp, d:int)->dynamic
var l_w=argument[0],l_i=argument[1],l_d=argument[3];
var l_r=l_w[l_i]+l_d;
l_w[@l_i]=l_r;
return l_r;

#define array_postfix
/// array_postfix(w:array<dynamic>, i:int, o:GmlOp, d:int)->dynamic
var l_w=argument[0],l_i=argument[1],l_d=argument[3];
var l_r=l_w[l_i];
l_w[@l_i]=l_r+l_d;
return l_r;

#define array_wget_2D
/// array_wget_2D(arr:array<dynamic>, row:int, col:int)->dynamic
var l_arr=argument[0],l_row=argument[1],l_col=argument[2];
return l_arr[l_row, l_col];

#define array_aop_2D
/// array_aop_2D(arr:array<dynamic>, row:int, col:int, op:GmlOp, val:dynamic)->dynamic
var l_arr=argument[0],l_row=argument[1],l_col=argument[2],l_op=argument[3],l_val=argument[4];
var l_out=l_arr[l_row, l_col];
switch(l_op){
	case 0:l_out*=l_val;break;
	case 1:l_out/=l_val;break;
	case 2:l_out%=l_val;break;
	case 3:l_out=(l_out div l_val);break;
	case 16:l_out+=l_val;break;
	case 17:l_out-=l_val;break;
	case 32:l_out=l_out<<l_val;break;
	case 33:l_out=l_out>>l_val;break;
	case 48:l_out|=l_val;break;
	case 49:l_out&=l_val;break;
	case 50:l_out^=l_val;break;
	case 64:l_out=l_out==l_val;break;
	case 65:l_out=l_out!=l_val;break;
	case 66:l_out=l_out<l_val;break;
	case 67:l_out=l_out<=l_val;break;
	case 68:l_out=l_out>l_val;break;
	case 69:l_out=l_out>=l_val;break;
}
l_arr[@l_row,l_col]=l_out;
return l_out;

#define array_prefix_2D
/// array_prefix_2D(arr:array<dynamic>, row:int, col:int, d:int)->dynamic
var l_arr=argument[0],l_row=argument[1],l_col=argument[2],l_d=argument[3];
var l_out=l_arr[l_row, l_col]+l_d;
l_arr[@l_row,l_col]=l_out;
return l_out;

#define array_postfix_2D
/// array_postfix_2D(arr:array<dynamic>, row:int, col:int, d:int)->dynamic
var l_arr=argument[0],l_row=argument[1],l_col=argument[2],l_d=argument[3];
var l_out=l_arr[l_row, l_col];
l_arr[@l_row,l_col]=l_out+l_d;
return l_out;

#define ds_list_aop
/// ds_list_aop(list:ds_list<dynamic>, i:int, op:GmlOp, val:dynamic)->dynamic
var l_list=argument[0],l_i=argument[1],l_op=argument[2],l_val=argument[3];
var l_out=l_list[|l_i];
switch(l_op){
	case 0:l_out*=l_val;break;
	case 1:l_out/=l_val;break;
	case 2:l_out%=l_val;break;
	case 3:l_out=(l_out div l_val);break;
	case 16:l_out+=l_val;break;
	case 17:l_out-=l_val;break;
	case 32:l_out=l_out<<l_val;break;
	case 33:l_out=l_out>>l_val;break;
	case 48:l_out|=l_val;break;
	case 49:l_out&=l_val;break;
	case 50:l_out^=l_val;break;
	case 64:l_out=l_out==l_val;break;
	case 65:l_out=l_out!=l_val;break;
	case 66:l_out=l_out<l_val;break;
	case 67:l_out=l_out<=l_val;break;
	case 68:l_out=l_out>l_val;break;
	case 69:l_out=l_out>=l_val;break;
}
l_list[|l_i]=l_out;
return l_out;

#define ds_list_prefix
/// ds_list_prefix(list:ds_list<dynamic>, i:int, d:int)->dynamic
var l_list=argument[0],l_i=argument[1],l_d=argument[2];
var l_out=l_list[|l_i]+l_d;
l_list[|l_i]=l_out;
return l_out;

#define ds_list_postfix
/// ds_list_postfix(list:ds_list<dynamic>, i:int, d:int)->dynamic
var l_list=argument[0],l_i=argument[1],l_d=argument[2];
var l_out=l_list[|l_i];
l_list[|l_i]=l_out+l_d;
return l_out;

#define ds_map_aop
/// ds_map_aop(map:ds_map<dynamic; dynamic>, key:dynamic, op:GmlOp, val:dynamic)->dynamic
var l_map=argument[0],l_key=argument[1],l_op=argument[2],l_val=argument[3];
var l_out=l_map[?l_key];
switch(l_op){
	case 0:l_out*=l_val;break;
	case 1:l_out/=l_val;break;
	case 2:l_out%=l_val;break;
	case 3:l_out=(l_out div l_val);break;
	case 16:l_out+=l_val;break;
	case 17:l_out-=l_val;break;
	case 32:l_out=l_out<<l_val;break;
	case 33:l_out=l_out>>l_val;break;
	case 48:l_out|=l_val;break;
	case 49:l_out&=l_val;break;
	case 50:l_out^=l_val;break;
	case 64:l_out=l_out==l_val;break;
	case 65:l_out=l_out!=l_val;break;
	case 66:l_out=l_out<l_val;break;
	case 67:l_out=l_out<=l_val;break;
	case 68:l_out=l_out>l_val;break;
	case 69:l_out=l_out>=l_val;break;
}
l_map[?l_key]=l_out;
return l_out;

#define ds_map_prefix
/// ds_map_prefix(map:ds_map<dynamic; dynamic>, key:dynamic, d:int)->dynamic
var l_map=argument[0],l_key=argument[1],l_d=argument[2];
var l_out=l_map[?l_key]+l_d;
l_map[?l_key]=l_out;
return l_out;

#define ds_map_postfix
/// ds_map_postfix(map:ds_map<dynamic; dynamic>, key:dynamic, d:int)->dynamic
var l_map=argument[0],l_key=argument[1],l_d=argument[2];
var l_out=l_map[?l_key];
l_map[?l_key]=l_out+l_d;
return l_out;

#define ds_grid_aop
/// ds_grid_aop(grid:ds_grid<dynamic>, x:int, y:int, op:GmlOp, val:dynamic)->dynamic
var l_grid=argument[0],l_x=argument[1],l_y=argument[2],l_op=argument[3],l_val=argument[4];
var l_out=l_grid[#l_x,l_y];
switch(l_op){
	case 0:l_out*=l_val;break;
	case 1:l_out/=l_val;break;
	case 2:l_out%=l_val;break;
	case 3:l_out=(l_out div l_val);break;
	case 16:l_out+=l_val;break;
	case 17:l_out-=l_val;break;
	case 32:l_out=l_out<<l_val;break;
	case 33:l_out=l_out>>l_val;break;
	case 48:l_out|=l_val;break;
	case 49:l_out&=l_val;break;
	case 50:l_out^=l_val;break;
	case 64:l_out=l_out==l_val;break;
	case 65:l_out=l_out!=l_val;break;
	case 66:l_out=l_out<l_val;break;
	case 67:l_out=l_out<=l_val;break;
	case 68:l_out=l_out>l_val;break;
	case 69:l_out=l_out>=l_val;break;
}
l_grid[#l_x,l_y]=l_out;
return l_out;

#define ds_grid_prefix
/// ds_grid_prefix(grid:ds_grid<dynamic>, x:int, y:int, d:int)->dynamic
var l_grid=argument[0],l_x=argument[1],l_y=argument[2],l_d=argument[3];
var l_out=l_grid[#l_x,l_y]+l_d;
l_grid[#l_x,l_y]=l_out;
return l_out;

#define ds_grid_postfix
/// ds_grid_postfix(grid:ds_grid<dynamic>, x:int, y:int, d:int)->dynamic
var l_grid=argument[0],l_x=argument[1],l_y=argument[2],l_d=argument[3];
var l_out=l_grid[#l_x,l_y];
l_grid[#l_x,l_y]=l_out+l_d;
return l_out;
