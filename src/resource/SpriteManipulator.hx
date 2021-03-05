package resource;

import haxe.Timer;
import js.lib.Promise;
import js.html.*;
import tools.EventHandler;
import Main.document;

/** Imports and manipulates sprites. */
class SpriteManipulator {
	private var canvas: CanvasElement;
	private var canvasContext: CanvasRenderingContext2D;
	private var image: Image;
	private var imageHasLoaded: Bool;

	public function new() {
		canvas = document.createCanvasElement();
		canvasContext = canvas.getContext2d();
	}

	public function setSprite(spritePath: String) {
		canvasContext.clearRect(0, 0, canvas.width, canvas.height);
		image = new Image();
		imageHasLoaded = false;
		image.onload = onImageLoad;
		image.src = spritePath;
	}

	public var onReady = new EventHandler();
	private function onImageLoad() {
		imageHasLoaded = true;
		canvas.width = image.width;
		canvas.height = image.height;
		canvasContext.drawImage(image, 0, 0);
		
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

	public function getBoundingBox(tolerance: Int): SpriteBoundingBox {

		var imageData = canvasContext.getImageData(0, 0, canvas.width, canvas.height);

		var width = canvas.width;
		var height = canvas.height;

		var minX = width;
		var minY = height;
		var maxX = 0;
		var maxY = 0;

		for (y in 0...height) {
			for (x in 0...width) {
				var index = (y * width + x)*4;
				if (imageData.data[index+3] > tolerance) {
					maxX = cast Math.max(maxX, x);
					maxY = cast Math.max(maxY, y);
					minX = cast Math.min(minX, x);
					minY = cast Math.min(minY, y);
				}
			}
		}

		// Nothing was found, big sad
		if (minX == width && minY == height && maxX == 0 && maxY == 0) {
			minX = 0;
			minY = 0;
			maxX = 0;
			maxY = 0;
		}

		return {left: minX, top: minY, right: maxX, bottom: maxY};
	}

	public static function MeasureSpriteAsync(spritePath: String): Promise<{width: Int, height: Int}> {
		return new Promise((resolve, reject) -> {
			var image = new Image();
			image.onload = () -> {
				resolve( {width: image.width, height: image.height} );
				image.src = "";
			}
			image.onerror = () -> {
				reject("Image failed to load");
			}
			image.src = spritePath;

		});
	}
}


typedef SpriteBoundingBox = {
	left: Int,
	top: Int,
	right: Int,
	bottom: Int
}