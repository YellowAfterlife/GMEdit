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
			"bboxMode": cast 0,
			"collisionKind": cast 1,
			"type": 0,
			"origin": cast 0,
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
			"frames": [ YySprite23Frame.generateDefault(spriteReference, imageGuid, layerGuid) ],
			"sequence": YySequence.generateDefaultSpriteSequence(spriteReference, imageGuid),
			"layers": [
			  YySprite23Layer.generateDefault(layerGuid),
			],
			"parent": parent,
			"resourceVersion": "1.0",
			"name": name,
			"tags": [],
			"resourceType": "GMSprite",
		  };
	}

	/**Clears current frames and replaces them with new ones*/
	public function replaceFrames(frameGuids: Array<YyGUID>) {
		this.frames = [];
		this.sequence.tracks[0].keyframes.Keyframes = [];
		for (frameGuid in frameGuids) {
			addFrame(frameGuid);
		}
	}

	public function addFrame(frameGuid: YyGUID, ?layerGuid: YyGUID) {
		var spritePath:String = 'sprites/${this.name}/${this.name}.yy';
		var thisReference:YyResourceRef = {name: this.name, path: spritePath}
		if (layerGuid == null) {
			layerGuid = cast this.layers[0].name;
		}

		var index: Int = this.frames.length;

		this.frames.push(
			YySprite23Frame.generateDefault( thisReference , frameGuid, layerGuid)
		);

		this.sequence.tracks[0].keyframes.Keyframes.push(
			YySequenceKeyframeSprite.generateDefault(thisReference, index, frameGuid)
		);

		this.sequence.length = this.frames.length;
		
	}
}

typedef YySprite23Impl = {
	>YyResource,
	bboxMode:SpriteBboxMode,
	collisionKind:SpriteBboxType,
	type:Int,
	origin:SpriteOriginType,
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
	layers:Array<YySprite23Layer>
}

enum abstract SpriteBboxMode(Int) {
	var Automatic = 0;
	var FullImage = 1;
	var Manual = 2;
}

enum abstract SpriteBboxType(Int) {
	var Precise = 0;
	var Rectangle = 1;
	var Ellipse = 2;
	var Diamond = 3;
	var PrecisePerFrame = 4;
	var RectangleWithRotation = 5;
}


enum abstract SpriteOriginType(Int) {
	var TopLeft = 0;
	var TopCentre = 1;
	var TopRight = 2;
	var MiddleLeft = 3;
	var MiddleCentre = 4;
	var MiddleRight = 5;
	var BottomLeft = 6;
	var BottomCentre = 7;
	var BottomRight = 8;
	var Custom = 9;
}

@:forward
abstract YySprite23Frame(YySprite23FrameImpl) from YySprite23FrameImpl to YySprite23FrameImpl {
	/**
	 * Create a new YySprite23Frame with the default values found in 2.3
	 */
	 public static function generateDefault(parentReference: YyResourceRef, imageGuid: YyGUID, layerGuid: YyGUID):YySprite23Frame {
		var thisReference = {name: imageGuid, path: parentReference.path}
		return {
			"compositeImage": {
				"FrameId": thisReference,
				"LayerId":null,
				"resourceVersion":"1.0",
				"name":"",
				"tags":[],
				"resourceType":"GMSpriteBitmap",
			},
			"images":[
				{
					"FrameId": thisReference,
					"LayerId": {"name": layerGuid,"path": parentReference.path,},
					"resourceVersion":"1.0",
					"name":"",
					"tags":[],
					"resourceType":"GMSpriteBitmap",
				},
		  	],
			"parent": parentReference,
			"resourceVersion":"1.0",
			"name": imageGuid,
			"tags":[],
			"resourceType":"GMSpriteFrame",}
	 }
}

typedef YySprite23FrameImpl = {
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

@:forward
abstract YySprite23Layer(YySprite23LayerImpl) from YySprite23LayerImpl to YySprite23LayerImpl {
	public static function generateDefault(layerGuid: YyGUID):YySprite23Layer {
		return {
			"visible":true,
			"isLocked":false,
			"blendMode":0,
			"opacity":100.0,
			"displayName":"default",
			"resourceVersion":"1.0",
			"name":layerGuid,
			"tags":[],
			"resourceType":"GMImageLayer",
		}
	}
}

typedef YySprite23LayerImpl = {
	>YyBase23,
	visible:Bool,
	isLocked:Bool,
	blendMode:Int,
	opacity:Float,
	displayName:String
}