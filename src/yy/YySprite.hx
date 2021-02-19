package yy;

import yy.YyResourceRef;
import yy.YySequence;
import yy.YyBase.YyBase23;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward
abstract YySprite(YySpriteImpl) from YySpriteImpl to YySpriteImpl {

}


typedef YySpriteImpl = {
	>YyResource,
	?xorig:Float,
	?yorig:Float,
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


@:forward
abstract YySprite23(YySprite23Impl) from YySprite23Impl to YySprite23Impl {
	/**
	 * Create a new YySprite23 with the default values found in 2.3
	 */
	public static function generateDefault(parent: YyResourceRef, name: String):YySprite23 {
		var imageGuid = new YyGUID();
		var layerGuid = new YyGUID();
		
		var spritePath:String = 'sprites/${name}/${name}.yy';
		var spriteReference:YyResourceRef = {name: name, path: spritePath};
		
		return {
			"bboxMode": 0,
			"collisionKind": 1,
			"type": 0,
			"origin": 0,
			"preMultiplyAlpha": false,
			"edgeFiltering": false,
			"collisionTolerance": 0,
			"swfPrecision": 2.525,
			"bbox_left": 0,
			"bbox_right": 0,
			"bbox_top": 0,
			"bbox_bottom": 0,
			"HTile": false,
			"VTile": false,
			"For3D": false,
			"width": 64,
			"height": 64,
			"textureGroupId": {
			  "name": "Default",
			  "path": "texturegroups/Default",
			},
			"swatchColours": null,
			"gridX": 0,
			"gridY": 0,
			"frames": [
			  	{
				  "compositeImage": {"FrameId":{"name": imageGuid,"path": spritePath},"LayerId":null,"resourceVersion":"1.0","name":"","tags":[],"resourceType":"GMSpriteBitmap",}
				  ,"images":[ {"FrameId":{"name":imageGuid,"path": spritePath,},"LayerId":{"name": layerGuid,"path": spritePath,},"resourceVersion":"1.0","name":"","tags":[],"resourceType":"GMSpriteBitmap",}],
				  "parent": spriteReference,"resourceVersion":"1.0","name":imageGuid,"tags":[],"resourceType":"GMSpriteFrame"
				}
			],
			"sequence": YySequence.generateDefaultSpriteSequence(spriteReference, [imageGuid]),
			"layers": [
			  {"visible":true,"isLocked":false,"blendMode":0,"opacity":100.0,"displayName":"default","resourceVersion":"1.0","name":layerGuid,"tags":[],"resourceType":"GMImageLayer",},
			],
			"parent": parent,
			"resourceVersion": "1.0",
			"name": name,
			"tags": [],
			"resourceType": "GMSprite",
		  };
	}
}

typedef YySprite23Impl = {
	>YyResource,
	bboxMode:Int,
	collisionKind:Int,
	type:Int,
	origin:Int,
	preMultiplyAlpha:Bool,
	edgeFiltering:Bool,
	collisionTolerance:Int,
	swfPrecision:Float,
	bbox_left:Int,
	bbox_right:Int,
	bbox_top:Int,
	bbox_bottom:Int,
	HTile:Bool,
	VTile:Bool,
	For3D:Bool,
	width:Int,
	height:Int,
	textureGroupId:{
		name:String,
		path:String
	},
	swatchColours:Any,
	gridX:Int,
	gridY:Int,
	sequence: YySequence,
	frames:Array<YySprite23Frame>,
	layers:Array<{
		>YyBase23,
		visible:Bool,
		isLocked:Bool,
		blendMode:Int,
		opacity:Float,
		displayName:String
	}>
}

typedef YySprite23Frame = {
	>YyBase23,
	compositeImage:{
		>YyBase23,
		FrameId: YyResourceRef,
		LayerId:Any
	},
	images:Array<{
		>YyBase23,
		FrameId: YyResourceRef,
		LayerId: YyResourceRef
	}>,
	parent: YyResourceRef
}