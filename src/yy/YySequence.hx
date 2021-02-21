package yy;

import haxe.DynamicAccess;
import yy.YyResourceRef;

@:forward
abstract YySequence(YySequenceImpl) from YySequenceImpl to YySequenceImpl {
	/**
	 * Create a new YySequence to use with a sprite populated with the default values found in 2.3
	 */
	 public static function generateDefaultSpriteSequence(spriteReference: YyResourceRef, imageIds: Array<String>):YySequence {
		
		var trackKeyframes:Array<YySequenceKeyframeSprite> = [];
		var i = 0;
		for (imageId in imageIds) {
			trackKeyframes.push(
				{"id":new YyGUID(),"Key":0.0,"Length": i++,"Stretch":false,"Disabled":false,"IsCreationKey":false,"Channels":{"0":{"Id":{"name":imageId,"path":spriteReference.path,},"resourceVersion":"1.0","resourceType":"SpriteFrameKeyframe",},},"resourceVersion":"1.0","resourceType":"Keyframe<SpriteFrameKeyframe>",}
			);
		}

		return {
			"spriteId": spriteReference,
			"timeUnits": 1,
			"playback": 1,
			"playbackSpeed": 30.0,
			"playbackSpeedType": cast 0,
			"autoRecord": true,
			"volume": 1.0,
			"length": imageIds.length,
			"events": {"Keyframes":[],"resourceVersion":"1.0","resourceType":"KeyframeStore<MessageEventKeyframe>",},
			"moments": {"Keyframes":[],"resourceVersion":"1.0","resourceType":"KeyframeStore<MomentsEventKeyframe>",},
			"tracks": [
			  {"name":"frames","spriteId":null,"keyframes":{"Keyframes": 
			  	trackKeyframes
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

typedef YySequenceKeyframeSprite = {
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