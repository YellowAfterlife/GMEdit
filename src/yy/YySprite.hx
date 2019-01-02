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
	>YyBase,
	name:String,
	xorig:Float,
	yorig:Float,
	width:Float,
	height:Float,
	playbackSpeed:Float,
	playbackSpeedType:Int,
	frames:Array<YySpriteFrame>,
};
typedef YySpriteFrame = {
	>YyBase,
	SpriteId:YyGUID,
};
