package editors.sprite;

import resource.SpriteManipulator;
import tools.EventHandler;

class BoundingBoxMeasurer {

	private var filePaths: Array<String>;
	private var spriteManipulator: SpriteManipulator;
	private var index: Int;
	private var boundingBox: SpriteBoundingBox;
	private var tolerance: Int;

	public function new(spriteManipulator: SpriteManipulator) {
		this.spriteManipulator = spriteManipulator;
	}

	public function start(filePaths: Array<String>, tolerance: Int) {
		this.filePaths = filePaths;
		this.tolerance = tolerance;
		this.index = 0;
		this.boundingBox = null;
		spriteManipulator.onReady.add(onReady);
		iterate();
	}

	public var onMeasured: EventHandler<SpriteBoundingBox> = new EventHandler();

	private function iterate() {
		if (index >= filePaths.length) {
			spriteManipulator.onReady.remove(onReady);
			if (boundingBox == null) {
				boundingBox = {left: 0, top: 0, bottom: 0, right: 0};
			}
			onMeasured.invoke(boundingBox);
			return;
		}
		// Looks clunky, but I fear setSprite can instantly trigger onReady and make the index whack
		var oldIndex = index;
		index++;
		spriteManipulator.setSprite(filePaths[oldIndex]);
	}
	
	private function onReady(_) {
		var newBb = spriteManipulator.getBoundingBox(tolerance);
		
		if (boundingBox == null) {
			boundingBox = newBb;
		} else {
			// All 0'd boxes are empty boxes, ignore them
			if (boundingBox.right != 0 || boundingBox.left != 0 || boundingBox.top != 0 || boundingBox.bottom != 0) {
				boundingBox = {
					left: cast Math.min(boundingBox.left, newBb.left),
					top: cast Math.min(boundingBox.top, newBb.top),
					right: cast Math.max(boundingBox.right, newBb.right),
					bottom: cast Math.max(boundingBox.bottom, newBb.bottom),
				};
			}
		}

		iterate();
	}
}
