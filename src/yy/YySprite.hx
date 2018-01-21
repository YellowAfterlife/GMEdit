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
	frames:Array<YySpriteFrame>,
};
typedef YySpriteFrame = {
	>YyBase,
	SpriteId:YyGUID,
};
