package yy;


/**Represents a 2.3 font*/
@:forward
abstract YySound(YySoundImpl) from YySoundImpl to YySoundImpl {
	/**
	 * Create a new YySound with the default values found in 2.3
	 */
	 public static function generateDefault(parent: YyResourceRef, name: String):YySound {
		return {
			"compression": 0,
			"volume": 1.0,
			"preload": false,
			"bitRate": 128,
			"sampleRate": 44100,
			"type": 0,
			"bitDepth": 1,
			"audioGroupId": {
			  "name": "audiogroup_default",
			  "path": "audiogroups/audiogroup_default",
			},
			"soundFile": "",
			"duration": 0.0,
			"parent": parent,
			"resourceVersion": "1.0",
			"name": name,
			"tags": [],
			"resourceType": "GMSound",
		}
	}
}

typedef YySoundImpl = {
	>YyResource,
	compression:Int,
	volume:Float,
	preload:Bool,
	bitRate:Int,
	sampleRate:Int,
	type:Int,
	bitDepth:Int,
	audioGroupId:{
		name:String,
		path:String
	},
	soundFile:String,
	duration:Float,
};

