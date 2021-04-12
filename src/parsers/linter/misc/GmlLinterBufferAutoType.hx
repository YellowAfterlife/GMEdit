package parsers.linter.misc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterBufferAutoType {
	public static var map:Dictionary<GmlType> = {
		"buffer_bool": GmlTypeDef.bool,
		//
		"buffer_u8": GmlTypeDef.int,
		"buffer_s8": GmlTypeDef.int,
		"buffer_u16": GmlTypeDef.int,
		"buffer_s16": GmlTypeDef.int,
		"buffer_u32": GmlTypeDef.int,
		"buffer_s32": GmlTypeDef.int,
		"buffer_u64": GmlTypeDef.int,
		//
		"buffer_f16": GmlTypeDef.number,
		"buffer_f32": GmlTypeDef.number,
		"buffer_f64": GmlTypeDef.number,
		//
		"buffer_text": GmlTypeDef.string,
		"buffer_string": GmlTypeDef.string,
	};
}