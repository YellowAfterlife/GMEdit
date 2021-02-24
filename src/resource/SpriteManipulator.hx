package resource;

import js.lib.Promise;
import js.html.*;
import tools.EventHandler;
import Main.document;

/** Imports and manipulates sprites. */
class SpriteManipulator {
	private var canvas: CanvasElement;
	private var image: Image;
	private var imageHasLoaded: Bool;

	public function new(spritePath: String) {
		canvas = document.createCanvasElement();
		image = new Image();
		imageHasLoaded = false;
		image.onload = onImageLoad;
		image.src = spritePath;
	}

	public var onReady = new EventHandler();
	private function onImageLoad() {
		imageHasLoaded = true;
		onReady.invoke(null);
	}

	public function getImageWidth(): Int {
		if (imageHasLoaded == false) {
			return -1;
		}
		return image.width;
	}
	
	public function getImageHeight(): Int {
		if (imageHasLoaded == false) {
			return -1;
		}
		return image.height;
	}

	public static function MeasureSpriteAsync(spritePath: String): Promise<{width: Int, height: Int}> {
		return new Promise((resolve, reject) -> {
			var image = new Image();
			image.onload = () -> {
				resolve( {width: image.width, height: image.height} );
			}
			image.onerror = () -> {
				reject("Image failed to load");
			}
			image.src = spritePath;

		});
	}
}