package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyBase = {
	// older:
	?id:YyGUID,
	?modelName:String,
	?mvc:String,
	
	// newer:
	?resourceType:String,
	?resourceVersion:String,
	
	// field order for YyJson
	?hxOrder:Array<String>,
};
