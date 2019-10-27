package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyProjectResource = {
	?Key:YyGUID,
	?Value:YyProjectResourceValue,
	//
	?name:String,
	?path:String,
};
typedef YyProjectResourceValue = {
	id:YyGUID,
	resourcePath:String,
	resourceType:String,
	/// GMEdit-only
	?resourceName:String,
};
