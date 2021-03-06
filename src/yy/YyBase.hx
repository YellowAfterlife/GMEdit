package yy;
import yy.YyResourceRef;
import haxe.DynamicAccess;

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
	?tags:Array<String>,
	
	// field order for YyJson
	?hxOrder:Array<String>,
	?hxDigits:DynamicAccess<Int>,
};

typedef YyBase23 = {
	name: String,
	resourceType:String,
	resourceVersion:String,
	tags:Array<String>,
}