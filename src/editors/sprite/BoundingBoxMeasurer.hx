package editors.sprite;

import resource.SpriteManipulator;
import tools.EventHandler;

class BoundingBoxMeasurer {

	private var filePaths: Array<String>;
	private var spriteManipulator: SpriteManipulator;
	private var index: Int;
	private var boundingBox: SpriteBoundingBox;

	public function new(filePaths: Array<String>, spriteManipulator: SpriteManipulator) {
		this.filePaths = filePaths;
		this.spriteManipulator = spriteManipulator;
		index = 0;

		spriteManipulator.onReady.add(onReady);
	}

	public function start() {
		iterate();
	}

	public var onMeasured: EventHandler<SpriteBoundingBox> = new EventHandler();

	private function iterate() {
		if (index >= filePaths.length) {
			spriteManipulator.onReady.remove(onReady);
			onMeasured.invoke(boundingBox);
			return;
		}

		spriteManipulator.setSprite(filePaths[index]);
		index++;
	}
	
	private function onReady(_) {
		var newBb = spriteManipulator.getBoundingBox();
		
		if (boundingBox == null) {
			boundingBox = newBb;
		} else {
			boundingBox = {
				left: cast Math.min(boundingBox.left, newBb.left),
				top: cast Math.min(boundingBox.top, newBb.top),
				right: cast Math.max(boundingBox.right, newBb.right),
				bottom: cast Math.max(boundingBox.bottom, newBb.bottom),
			};
		}

		iterate();
	}
}
