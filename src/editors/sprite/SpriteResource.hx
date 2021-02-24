package editors.sprite;

import yy.YyGUID;
import yy.YySequence.PlaybackSpeedType;
import tools.EventHandler;
import yy.YySprite;


/** Wrapper around a YySprite. It contains subscribeable events so it can be used almost like a ViewModel */
@:build(tools.EventBuildingMacro.build())
class SpriteResource {
	public var frames(default, null):SpriteResourceFrames;
	var spriteData: YySprite23;

	public function new(spriteData: YySprite23) {
		this.spriteData = spriteData;
		this.frames = new SpriteResourceFrames(spriteData);
	}

	private var _unsavedChanges: Bool = false;
	@:observable(this._unsavedChanges)
	var unsavedChanges: Bool;

	@:observable(spriteData.sequence.xorigin, {setOriginType(SpriteOriginType.Custom); unsavedChanges = true;} )
	var originX: Int;

	@:observable(spriteData.sequence.yorigin, {setOriginType(SpriteOriginType.Custom); unsavedChanges = true;})
	var originY: Int;

	public var onOriginTypeChanged: EventHandler<SpriteOriginType> = new EventHandler();
	public var originType(get, null): SpriteOriginType;
	private function get_originType(): SpriteOriginType {
		return spriteData.origin;
	}

	/** 
	 * Sets the current origin type. This will update the the originX and originY values if not set to custom
	 */
	public function setOriginType(type: SpriteOriginType): SpriteOriginType {
		if (type == spriteData.origin) return type;

		if (type != SpriteOriginType.Custom) {
			var typeAsNumber: Int = cast type;
			var xInt = typeAsNumber % 3;
			var yInt = Math.floor(typeAsNumber / 3);

			var oldX = originX;
			var oldY = originY;

			spriteData.sequence.xorigin = Math.round(width/2 * xInt);
			spriteData.sequence.yorigin = Math.round(height/2 * yInt);

			if (oldX != originX) {
				onOriginXChanged.invoke(originX);
			}
			if (oldY != originY) {
				onOriginYChanged.invoke(originY);
			}
		}

		spriteData.origin = type;
		unsavedChanges = true;
		onOriginTypeChanged.invoke(type);
		return type;
	}

	@:observable(spriteData.width, unsavedChanges = true)
	var width: Int;

	@:observable(spriteData.height, unsavedChanges = true)
	var height: Int;

	@:observable(spriteData.sequence.playbackSpeedType, unsavedChanges = true)
	var playbackSpeedType: PlaybackSpeedType;

	@:observable(spriteData.sequence.playbackSpeed, unsavedChanges = true)
	var playbackSpeed: Float;

	@:observable(spriteData.bbox_left, unsavedChanges = true)
	var bboxLeft: Int;

	@:observable(spriteData.bbox_right, unsavedChanges = true)
	var bboxRight: Int;

	@:observable(spriteData.bbox_top, unsavedChanges = true)
	var bboxTop: Int;

	@:observable(spriteData.bbox_bottom, unsavedChanges = true)
	var bboxBottom: Int;

	/** Layer 0, the layer most people use*/
	public var defaultLayer(get, null): String;
	private function get_defaultLayer(): String {
		return spriteData.layers[0].name;
	}

	/** 
	 * Gets the underlying data. Only use when necessary, like when you need to send the data in for saving 
	 * If you call this to access a not exposed field, please make it an observable instead.
	 */
	public function getUnderlyingData():YySprite23 {
		return spriteData;
	}
}

@:forward
abstract SpriteResourceFrames(SpriteResourceFramesImpl) {
	@:op([]) public function arrayAccess(index:Int) : SpriteResourceFrame {
		return this.get(index);
	}

	public function new(spriteData: YySprite23) {
		this = new SpriteResourceFramesImpl(spriteData);
	}
}

class SpriteResourceFramesImpl {
	var spriteData: YySprite23;
	
	var array: Array<SpriteResourceFrame>;

	public function new(spriteData: YySprite23) {
		this.spriteData = spriteData;
		this.array = new Array<SpriteResourceFrame>();
		for (i in 0 ... this.spriteData.frames.length) {
			this.array.push(new SpriteResourceFrame(spriteData, i));
		}
	}

	public var onFramesReplaced: EventHandler<Void> = new EventHandler();
	/**
	 * Replace all frames in the resource with new ones. Basically clearing the old images and adding new ones.	
	 */
	 public function replaceFrames(frameGuids: Array<YyGUID>) {
		spriteData.replaceFrames(frameGuids);
		this.array = [];
		for (i in 0 ... this.spriteData.frames.length) {
			this.array.push(new SpriteResourceFrame(spriteData, i));
		}
	}

	public var onFrameAdded: EventHandler<{frame:SpriteResourceFrame, index:Int}> = new EventHandler();
	/** Add a new frame to the sprite*/
	public function add(frameId: YyGUID, ?layerId: YyGUID) {
		this.spriteData.addFrame(frameId, layerId);
		var index = array.length;
		var frame = new SpriteResourceFrame(this.spriteData, index);
		array.push( frame );
		onFrameAdded.invoke({frame:frame, index: index});
	}

	public function get(index: Int): SpriteResourceFrame {
		return this.array[index];
	}

	/** Number of frames inside the collection*/
	public var length(get, null): Int;
	private function get_length():Int {
		return array.length;
	}

	public function iterator():Iterator<SpriteResourceFrame> {
		return array.iterator();
	}
}

class SpriteResourceFrame {
	var spriteData: YySprite23;
	var spriteFrame: YySprite23Frame;
	public function new(spriteData: YySprite23, index: Int) {
		this.spriteData = spriteData;
		this.spriteFrame = this.spriteData.frames[index];
	}

	public var id(get, null): String;
	private function get_id():String {
		return spriteFrame.name;
	}

	public var imagePath(get, null): String;
	private function get_imagePath():String {
		return id + ".png";
	}
}