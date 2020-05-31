package yy;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward
abstract YySprite(YySpriteImpl) from YySpriteImpl to YySpriteImpl {
	//
}
typedef YySpriteImpl = {
	>YyResource,
	xorig:Float,
	yorig:Float,
	width:Float,
	height:Float,
	playbackSpeed:Float,
	playbackSpeedType:Int,
	frames:Array<YySpriteFrame>,
	For3D:Bool,
	HTile:Bool,
	VTile:Bool,
};
typedef YySpriteFrame = {
	>YyBase,
	SpriteId:YyGUID,
	/** 2.3, but still an ID */
	?name:String,
};
