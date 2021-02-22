package yy;

import haxe.DynamicAccess;
import yy.YyResourceRef;

@:forward
abstract YySequence(YySequenceImpl) from YySequenceImpl to YySequenceImpl {
	/**
	 * Create a new YySequence to use with a sprite populated with the default values found in 2.3
	 */
	 public static function generateDefaultSpriteSequence(spriteReference: YyResourceRef, imageId: String):YySequence {
		
		var trackKeyframes:Array<YySequenceKeyframeSprite> = [];

		return {
			"spriteId": spriteReference,
			"timeUnits": 1,
			"playback": 1,
			"playbackSpeed": 30.0,
			"playbackSpeedType": cast 0,
			"autoRecord": true,
			"volume": 1.0,
			"length": 1,
			"events": {"Keyframes":[],"resourceVersion":"1.0","resourceType":"KeyframeStore<MessageEventKeyframe>",},
			"moments": {"Keyframes":[],"resourceVersion":"1.0","resourceType":"KeyframeStore<MomentsEventKeyframe>",},
			"tracks": [
			  {"name":"frames","spriteId":null,"keyframes":{"Keyframes": 
			  	[YySequenceKeyframeSprite.generateDefault(spriteReference, 0, imageId)]
				,"resourceVersion":"1.0","resourceType":"KeyframeStore<SpriteFrameKeyframe>",},"trackColour":0,"inheritsTrackColour":true,"builtinName":0,"traits":0,"interpolation":1,"tracks":[],"events":[],"modifiers":[],"isCreationTrack":false,"resourceVersion":"1.0","tags":[],"resourceType":"GMSpriteFramesTrack",},
			],
			"visibleRange": null,
			"lockOrigin": false,
			"showBackdrop": true,
			"showBackdropImage": false,
			"backdropImagePath": "",
			"backdropImageOpacity": 0.5,
			"backdropWidth": 1366,
			"backdropHeight": 768,
			"backdropXOffset": 0.0,
			"backdropYOffset": 0.0,
			"xorigin": 0,
			"yorigin": 0,
			"eventToFunction": {},
			"eventStubScript": null,
			"parent": spriteReference,
			"resourceVersion": "1.3",
			"name": "sBlood",
			"tags": [],
			"resourceType": "GMSequence",
		  }

	 }
}


typedef YySequenceImpl = {
	>YyResource,
	
	spriteId: YyResourceRef,
	timeUnits:Int,
	playback:Int,
	playbackSpeed:Float,
	playbackSpeedType: PlaybackSpeedType,
	autoRecord:Bool,
	volume:Float,
	length:Float,
	events: YySequenceKeyframeStore<Any>,
	moments: YySequenceKeyframeStore<Any>,
	tracks:Array<{
		name:String,
		spriteId:Any,
		keyframes: YySequenceKeyframeStore<YySequenceKeyframeSprite>,
		trackColour:Int,
		inheritsTrackColour:Bool,
		builtinName:Int,
		traits:Int,
		interpolation:Int,
		tracks:Array<Any>,
		events:Array<Any>,
		modifiers:Array<Any>,
		isCreationTrack:Bool,
		resourceVersion:String,
		tags:Array<Any>,
		resourceType:String
	}>,
	visibleRange:Any,
	lockOrigin:Bool,
	showBackdrop:Bool,
	showBackdropImage:Bool,
	backdropImagePath:String,
	backdropImageOpacity:Float,
	backdropWidth:Int,
	backdropHeight:Int,
	backdropXOffset:Float,
	backdropYOffset:Float,
	xorigin:Int,
	yorigin:Int,
	eventToFunction:{},
	eventStubScript:Any

};

enum abstract PlaybackSpeedType(Int) {
	var FramesPerSecond = 0;
	var FramesPerGameFrame = 1;
}

@:forward
abstract YySequenceKeyframeSprite(YySequenceKeyframeSpriteImpl) from YySequenceKeyframeSpriteImpl to YySequenceKeyframeSpriteImpl {
	/**
	 * Create a new KeyframeSprite to use with a sprite populated with the default values found in 2.3
	 */
	 public static function generateDefault(spriteReference: YyResourceRef, index: Int, frameGuid: String):YySequenceKeyframeSprite {
		return {
			"id": new YyGUID(),
			"Key": index,
			"Length": 1.0,
			"Stretch":false,
			"Disabled":false,
			"IsCreationKey":false,
			"Channels": {
				"0": {
					"Id": {"name": frameGuid,"path":spriteReference.path,},
					"resourceVersion":"1.0",
					"resourceType":"SpriteFrameKeyframe"
				},
			},
			"resourceVersion":"1.0",
			"resourceType":"Keyframe<SpriteFrameKeyframe>",
		}
	 }
}

typedef YySequenceKeyframeSpriteImpl = {
	id:String,
	Key:Float,
	Length:Float,
	Stretch:Bool,
	Disabled:Bool,
	IsCreationKey:Bool,
	Channels: DynamicAccess<YySequenceKeyframeChannel>,
	resourceVersion:String,
	resourceType:String
}

typedef YySequenceKeyframeChannel = {
	Id: YyResourceRef,
	resourceVersion:String,
	resourceType:String
} 

typedef YySequenceKeyframeStore<T> = {
	Keyframes:Array<T>,
	resourceVersion:String,
	resourceType:String
}