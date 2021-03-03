package editors.sprite;

import js.lib.Promise;
import resource.SpriteManipulator;
import gml.Project;
import yy.YyJson;
import yy.YyGUID;
import editors.sprite.SpriteResource.SpriteResourceFrame;
import electron.FileSystem;
import electron.Dialog;
import tools.macros.SynSugar;
import editors.Editor;
import electron.FileWrap;
import gml.file.GmlFile;
import haxe.io.Path;
import js.html.*;
import file.kind.yy.KYySprite;
using tools.HtmlTools;
import Main.document;
import Main.window;
import electron.Shell;
import Lambda;

/**
 * This is a big mess as for something that's just an image strip viewer.
 * @author YellowAfterlife
 */
class EditSprite extends Editor {
	var sprite:SpriteResource;
	var panner:Panner;
	var framesContainer: DivElement;
	var frameCount:Int = 0;
	var currentFrame:Int = 0;
	var currentFrameElement:DivElement;
	var framesData: Array<FrameData> = [];
	var playbackDelta:Int = 1;
	var recenter = true;
	var animToggle:InputElement;
	var boundingBoxMeasurer: BoundingBoxMeasurer;
	var spriteManipulatorBusy = false;
	var spriteManipulator: SpriteManipulator;

	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		element.id = "sprite-editor";

		spriteManipulator = new SpriteManipulator();
		element.tabIndex = 0;
		element.addEventListener("keydown", function(e:KeyboardEvent) {
			if (document.activeElement.nodeName == "INPUT") return;
			
			// animation controls:
			if (frameCount > 1) switch (e.key) {
				case "ArrowLeft": adjustCurrentFrame( -1).scrollIntoView();
				case "ArrowRight": adjustCurrentFrame(1).scrollIntoView();
				case " ": animToggle.click();
			}
		});
	}

	function checkRecenter() {
		if (!recenter) return;
		panner.recenter();
		recenter = false;
	}
	override public function focusGain(prev:Editor):Void {
		super.focusGain(prev);
		checkRecenter();
	}
	//
	function setCurrentFrameElement(i:Int, ?frame:DivElement):DivElement {
		if (frame == null) frame = framesData[i].element;
		if (currentFrameElement == frame) return frame;
		currentFrameElement.classList.remove("current");
		frame.classList.add("current");
		currentFrameElement = frame;
		panner.image.src = framesData[i].url;
		return frame;
	}
	function adjustCurrentFrame(delta:Int):DivElement {
		if (frameCount <= 1) return null;
		currentFrame = (currentFrame + delta) % frameCount;
		if (currentFrame < 0) currentFrame += frameCount;
		return setCurrentFrameElement(currentFrame);
	}
	override public function load(data:Dynamic):Void {
		var v2 = Std.is(file.kind, KYySprite);
		if (v2 && data == null) data = FileWrap.readYyFileSync(file.path);
		
		sprite = new SpriteResource(data);
		sprite.onUnsavedChangesChanged.add(x -> {
			file.changed = x;
		});

		buildHtml();
	}

	public override function save(): Bool {
		var newSpriteJson = YyJson.stringify(sprite.getUnderlyingData(), Project.current.yyExtJson);
		file.writeContent(newSpriteJson);
		sprite.unsavedChanges = false;

		return true;
	}

	private function getImagePath(frame: SpriteResourceFrame):String {
		var dir = Path.directory(file.path);
		return Path.join([dir, frame.id + ".png"]);
	}
	
	override public function checkChanges():Void {
		if (!Path.isAbsolute(file.path)) return;
		/*
		var t1 = FileWrap.mtimeSync(file.path);
		if (t1 != file.time) {
			file.time = t1;
			load(null);
			return;
		}
		
		// if a single frame of the sprite is updated,
		// we might as well just update that element+URL:
		for (i in 0 ... frameTimes.length) {
			var framePath = framePaths[i];
			t1 = FileWrap.mtimeSync(framePath);
			if (t1 != frameTimes[i]) {
				frameTimes[i] = t1;
				var url = FileWrap.getImageURL(framePaths[i]);
				frameURLs[i] = url;
				frameElements[i].style.backgroundImage = 'url($url)';
				if (currentFrame == i) panner.image.src = url;
			}
		}*/
	}

	private function onSpriteImport() {
		Dialog.showOpenDialog({
			title: "Open",
			buttonLabel: "Import",
			properties: [ DialogOpenFeature.multiSelections ],
			filters: [
				new DialogFilter( "Image files", ["png"])
			]
		}, function(array: Array<String>) {
			if (array == null || array.length == 0) {
				return;
			}
			
			var newFiles = array.filter(x -> FileSystem.existsSync(x));
			if (newFiles.length == 0) {
				return;
			}
			
			
			// Measure the new sprites, abort if their size differ
			var measurePromises = [for (newFile in newFiles) SpriteManipulator.MeasureSpriteAsync(newFile)];

			Promise.all(measurePromises).then(promiseResult -> { // Start of measure promise. Purposefully not indented
			var newFileMeasurements:Array<{width: Int, height: Int}> = cast promiseResult;
			
			var width = newFileMeasurements[0].width;
			var height = newFileMeasurements[0].height;

			for (i in 1...newFileMeasurements.length) {
				var measure = newFileMeasurements[i];
				if (measure.width != width ||
				    measure.height != height) {

					Dialog.showAlert(
						"Can't import images that are not the same dimensions.\n" +
						'${newFiles[0]} is ${width}x${height}.\n' + 
						'${newFiles[i]} is ${measure.width}x${measure.height}.'
					);
					return;
				
				}
			}

			// Delete all old files
			for (frame in sprite.frames) {
				var path = getImagePath(frame);
				FileSystem.unlinkSync(path);
			}
			var directory = Path.directory(file.path);
			var layerDirectory = Path.join( [directory, "layers"]);
			// Delete the entire layer folder
			FileSystem.rmdirSync( layerDirectory, {recursive: true} );
			// And create it anew, nice and fresh
			FileSystem.mkdirSync(layerDirectory);

			var layerId = sprite.defaultLayer;
			var newIds:Array<YyGUID> = [];

			// Import new images
			for (newFile in newFiles) {
				var newId = new YyGUID();
				newIds.push(newId);

				FileSystem.mkdirSync( Path.join([layerDirectory, newId]));
				FileSystem.copyFileSync(newFile, Path.join([layerDirectory, newId, layerId + ".png"]));
				FileSystem.copyFileSync(newFile, Path.join([directory, newId + ".png"]));
			}

			sprite.frames.replaceFrames(newIds);
			sprite.width = width;
			sprite.height = height;

			// A save to save the new path, since we can get stray files otherwise.
			save();

			// Start measuring the bounding box for our new sprite			
			var spriteFrames = [for (frame in sprite.frames) frame];

			spriteManipulatorBusy = true;
			boundingBoxMeasurer = new BoundingBoxMeasurer(spriteFrames.map(x -> getImagePath(x)), spriteManipulator);
			boundingBoxMeasurer.onMeasured.add(onSpriteInitialMeasureReady);
			boundingBoxMeasurer.start();

			}); // End of measure promise. Purposefully not indented

		});
	}

	private function onSpriteInitialMeasureReady(_) {
		var bbox = spriteManipulator.getBoundingBox();

		sprite.bboxBottom = bbox.bottom;
		sprite.bboxLeft = bbox.left;
		sprite.bboxTop = bbox.top;
		sprite.bboxRight = bbox.right;

		save();
	
		spriteManipulatorBusy = false;
		spriteManipulator.onReady.remove(onSpriteInitialMeasureReady);
	}

	private function buildHtml() {
		element.clearInner();
		
		buildOptions();
		bindOptions();

		buildPreview();
	}

	private function bindOptions() {
		var importButton = element.querySelector("#import-button");
		importButton.addEventListener('click', onSpriteImport);

		{
			var originXElement:InputElement = cast element.querySelector("#origin-x");
			originXElement.value = Std.string(sprite.originX);
			var xUpdate = () -> sprite.originX = cast originXElement.valueAsNumber;
			originXElement.addEventListener('change', xUpdate);
			originXElement.addEventListener('input', xUpdate);
			sprite.onOriginXChanged.add(x -> originXElement.value = Std.string(x));
		}
		{
			var originYElement:InputElement = cast element.querySelector("#origin-y");
			originYElement.value = Std.string(sprite.originY);
			var yUpdate = () -> sprite.originY = cast originYElement.valueAsNumber;
			originYElement.addEventListener('change', yUpdate);
			originYElement.addEventListener('input', yUpdate);
			sprite.onOriginYChanged.add(y -> originYElement.value = Std.string(y));
			
		}
		{
			var originTypeElement:SelectElement = cast element.querySelectorAuto("#origin-type");
			HtmlTools.setSelectedValue(originTypeElement, Std.string(sprite.originType));
			originTypeElement.addEventListener('change', () -> sprite.setOriginType(cast Std.parseInt(originTypeElement.value)));
			sprite.onOriginTypeChanged.add(x -> HtmlTools.setSelectedValue(originTypeElement, Std.string(sprite.originType)));
		}
	}

	private function buildOptions() {
		var options = document.createDivElement();
		options.id = "sprite-options";

		options.innerHTML = SynSugar.xmls(<html>
			<h2>SpriteName</h2>
			<button id="import-button" class="highlighted-button">Import Image</button>
			
			<div>
				<div>
					<input type="number" id="origin-x"></input>
					<span>x</span>
					<input type="number" id="origin-y"></input>
				</div>
				<select id="origin-type">
					<option value="9">Custom</option>
					<option value="0">Top Left</option>
					<option value="1">Top Centre</option>
					<option value="2">Top Right</option>
					<option value="3">Middle Left</option>
					<option value="4">Middle Centre</option>
					<option value="5">Middle Right</option>
					<option value="6">Bottom Left</option>
					<option value="7">Bottom Centre</option>
					<option value="8">Bottom Right</option>
				</select>
			</div>
		</html>);
		element.appendChild(options);
	}

	private function buildPreview() {
		//
		var previewContainer = document.createDivElement();
		previewContainer.classList.add("resinfo");
		previewContainer.classList.add("sprite");


		{
			var spriteInfoContainer = document.createDivElement();
			spriteInfoContainer.classList.add("sprite-info");

			//
			framesContainer = document.createDivElement();
			framesContainer.classList.add("frames");

			spriteInfoContainer.appendChild(framesContainer);
				
			previewContainer.appendChild(spriteInfoContainer);
			
			fillFrameContainerContent();
			sprite.frames.onFramesReplaced.add( (_) -> fillFrameContainerContent());
		}

		{
			var pan = document.createDivElement();

			var imgCtr = document.createDivElement();
			recenter = true;
			{
				var img = document.createImageElement();
				img.onload = function(_) {
					img.onload = null;
					checkRecenter();
				}
				var framePath = getImagePath(sprite.frames[0]);
				img.src = FileWrap.getImageURL(framePath);
				imgCtr.appendChild(img);
			}
			{
				var spriteBorder = document.createDivElement();
				spriteBorder.classList.add("panner-element");
				spriteBorder.style.width = '${sprite.width}px';
				sprite.onWidthChanged.add(x -> {
					spriteBorder.style.width = '${x}px';
				});
				spriteBorder.style.height = '${sprite.height}px';
				sprite.onHeightChanged.add(x -> {
					spriteBorder.style.height = '${x}px';
				});
				spriteBorder.style.border = "1px solid rgba(255, 255, 255, 0.5)";
				imgCtr.appendChild(spriteBorder);
			}
			{
				var originCross = buildOriginCross();
				imgCtr.appendChild(originCross);
			}

			pan.appendChild(imgCtr);
			panner = new Panner(pan, imgCtr);
			previewContainer.appendChild(pan);
		}

		element.appendChild(previewContainer);
	}

	private function fillFrameContainerContent() {
		framesData = [];
		framesContainer.clearInner();

		for (frame in sprite.frames) {
			var framePath = getImagePath(frame);
			var url = FileWrap.getImageURL(framePath);
			var frame = document.createDivElement();
			var index = framesData.length;
			if (index == 0) {
				currentFrameElement = frame;
				frame.classList.add("current");
			}
			frame.title = "" + index;
			framesData.push({
				element: frame,
				url: url,
				path: framePath,
				importTime: FileWrap.mtimeSync(framePath)
			});

			//
			frame.classList.add("frame");
			if (sprite.width > 48 || sprite.height > 48) {
				frame.style.backgroundSize = "contain";
			}
			// something isn't right here, why do we only need to escape this here of all places?
			url = StringTools.replace(url, " ", "%20");
			//
			frame.style.backgroundImage = 'url($url)';
			if (sprite.width <= 24 && sprite.height <= 24) {
				frame.style.backgroundSize = '${sprite.width * 2}px ${sprite.height * 2}px';
				frame.classList.add("zoomed");
			}
			frame.onclick = function(_) {
				currentFrame = index;
				setCurrentFrameElement(index, frame);
			}
			frame.ondblclick = function(_) {
				Shell.openExternal(url);
			};
			framesContainer.appendChild(frame);
		}
		
	}

	private function buildOriginCross(): Element {
		var originCross = document.createParagraphElement();
		originCross.classList.add("panner-element");
		originCross.classList.add("origin");
		originCross.innerText = "+";

		var grabbed = false;
		originCross.style.left = '${sprite.originX}px';
		sprite.onOriginXChanged.add(x -> {
			if (grabbed) return;
			originCross.style.left = '${x}px';
		});
		originCross.style.top = '${sprite.originY}px';
		sprite.onOriginYChanged.add(y -> {
			if (grabbed) return;
			originCross.style.top = '${y}px';
		});


		var startX: Float = 0;
		var startY: Float = 0;

		function onMouseMove(e: MouseEvent) {
			e.preventDefault();

			var diffX = (e.clientX - startX)/panner.mult;
			var diffY = (e.clientY - startY)/panner.mult;

			originCross.style.left = (diffX) + "px";
			originCross.style.top = (diffY) + "px";
			
			sprite.originX = Math.round(diffX);
			sprite.originY = Math.round(diffY);
		}

		function onMouseUp() {
			document.removeEventListener('mouseup', onMouseUp);
			document.removeEventListener('mousemove', onMouseMove);
			grabbed = false;
		}

		function onMouseDown(e: MouseEvent) {
			e.preventDefault();
			e.stopPropagation();

			startX = (e.clientX - Std.parseInt(originCross.style.left)*panner.mult);
			startY = (e.clientY - Std.parseInt(originCross.style.top)*panner.mult);

			document.addEventListener('mouseup', onMouseUp);
			document.addEventListener('mousemove', onMouseMove);
			grabbed = true;
		}

		originCross.addEventListener('mousedown', onMouseDown);


		return originCross;
	}
}

typedef FrameData = {
	var url: String;
	var path: String;
	var element: DivElement;
	var importTime: Float;
}