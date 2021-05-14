package ace.extern;

/**
 * ...
 * @author YellowAfterlife
 */
typedef AceAnnotation = {
	row:Int,
	column:Int,
	/** "warning", "error", or "info" */
	?type:String,
	/** If set, overrides `type` */
	?className:String,
	text:String
}
typedef AceAnnotationPerRow = {
	text:Array<String>,
	?className:String,
};