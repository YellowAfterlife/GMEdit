package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyView = {
	>YyBase,
	name:YyGUID,
	children:Array<YyGUID>,
	filterType:String,
	folderName:String,
	isDefaultView:Bool,
	localisedFolderName:String,
}
