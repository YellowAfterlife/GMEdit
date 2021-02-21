package editors.sprite;

import tools.EventHandler;
import yy.YySprite;

/** Wrapper around a YySprite. It contains subscribeable events so it can be used almost like a ViewModel */
class SpriteResource {
	var spriteData: YySprite23;

	public function new(spriteData: YySprite23) {
		this.spriteData = spriteData;
	}

	public var onOriginXChanged = new EventHandler<Int>();
	public var originX(get, set): Int;
	private function get_originX():Int {
		return spriteData.sequence.xorigin;
	}
	private function set_originX(value: Int): Int {
		if (value == spriteData.sequence.xorigin) return value;

		spriteData.sequence.xorigin = value;
		onOriginXChanged.invoke(value);
		return value;
	}

	public var onOriginYChanged = new EventHandler<Int>();
	public var originY(get, set): Int;
	private function get_originY():Int {
		return spriteData.sequence.yorigin;
	}
	private function set_originY(value: Int): Int {
		if (value == spriteData.sequence.yorigin) return value;

		spriteData.sequence.yorigin = value;
		onOriginYChanged.invoke(value);
		return value;
	}
}