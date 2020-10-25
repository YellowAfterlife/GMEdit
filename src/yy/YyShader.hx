package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyShader = {
	>YyResource,
	type:Int,
}
class YyShaderDefaults {
	public static var baseFragGLSL:String = 'varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main() {
	gl_FragColor = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
}';
	public static var baseVertGLSL:String = 'attribute vec3 in_Position; // (x, y, z)
attribute vec4 in_Colour; // (r, g, b, a)
attribute vec2 in_TextureCoord; // (u, v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main() {
	vec4 object_space_pos = vec4(in_Position.x, in_Position.y, in_Position.z, 1.0);
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;

	v_vColour = in_Colour;
	v_vTexcoord = in_TextureCoord;
}';
}