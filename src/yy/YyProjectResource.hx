package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyProjectResource = {
	?Key:YyGUID,
	?Value:YyProjectResourceValue,
	//
	?id:YyResourceRef
};
typedef YyProjectResourceValue = {
	id:YyGUID,
	resourcePath:String,
	resourceType:String,
	/// GMEdit-only
	?resourceName:String,
};
