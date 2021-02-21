package editors.sprite;

import yy.YySequence.PlaybackSpeedType;
import electron.FileWrap;
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

	@:observable(spriteData.sequence.xorigin)
	var originX: Int;

	@:observable(spriteData.sequence.yorigin)
	var originY: Int;

	@:observable(spriteData.width)
	var width: Int;

	@:observable(spriteData.height)
	var height: Int;

	@:observable( spriteData.sequence.playbackSpeedType )
	var playbackSpeedType: PlaybackSpeedType;

	@:observable( spriteData.sequence.playbackSpeed )
	var playbackSpeed: Float;


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

	public function get(index: Int): SpriteResourceFrame {
		return this.array[index];
	}

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