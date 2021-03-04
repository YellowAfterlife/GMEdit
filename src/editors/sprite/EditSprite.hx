package editors.sprite;

import js.Browser;
import yy.YySequence.PlaybackSpeedType;
import yy.YySprite.SpriteBboxMode;
import tools.EventHandler;
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
	var currentFrame:Int = 0;
	var currentFrameElement:DivElement;
	var framesData: Array<FrameData> = [];
	var playingBack = false;
	var recenter = true;
	var playButton: SpanElement;
	var boundingBoxMeasurer: BoundingBoxMeasurer;
	var spriteManipulatorBusy = false;
	var spriteManipulator: SpriteManipulator;
	/** If we should perform a save when measurement is complete*/
	var saveMeasurement: Bool = false;
	var projectRoomSpeed: Int = 60;

	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		element.id = "sprite-editor";

		spriteManipulator = new SpriteManipulator();
		boundingBoxMeasurer = new BoundingBoxMeasurer(spriteManipulator);
		boundingBoxMeasurer.onMeasured.add(onSpriteMeasureReady);
		element.tabIndex = 0;
		element.addEventListener("keydown", function(e:KeyboardEvent) {
			if (document.activeElement.nodeName == "INPUT") return;
			
			// animation controls:
			if (framesData.length > 1) switch (e.key) {
				case "ArrowLeft": adjustCurrentFrame( -1).scrollIntoView();
				case "ArrowRight": adjustCurrentFrame(1).scrollIntoView();
				case " ": playButton.click();
			}
		});
		projectRoomSpeed = Project.current.getFrameRate();
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
		if (framesData.length <= 1) return null;
		currentFrame = (currentFrame + delta) % framesData.length;
		if (currentFrame < 0) currentFrame += framesData.length;
		return setCurrentFrameElement(currentFrame);
	}
	override public function load(data:Dynamic):Void {
		var v2 = Std.is(file.kind, KYySprite);
		if (v2 && data == null) data = FileWrap.readYyFileSync(file.path);
		
		sprite = new SpriteResource(data);
		sprite.onUnsavedChangesChanged.add(x -> {
			file.changed = x;
		});

		var triggerBboxCheck = (_: Dynamic) -> {

			if (sprite.bboxMode == SpriteBboxMode.Automatic) {
				var spriteFrames = [for (frame in sprite.frames) frame];
				boundingBoxMeasurer.start(spriteFrames.map(x -> getImagePath(x)), sprite.bboxTolerance);
			} else if (sprite.bboxMode == SpriteBboxMode.FullImage) {
				sprite.bboxTop = 0;
				sprite.bboxLeft = 0;
				sprite.bboxRight = sprite.width-1;
				sprite.bboxBottom = sprite.height-1;
			}
		}

		// On bbox requiring changing
		sprite.onBboxToleranceChanged.add(triggerBboxCheck);
		sprite.onBboxModeChanged.add(triggerBboxCheck);

		buildHtml();
	}

	public override function save(): Bool {
		var newSpriteJson = YyJson.stringify(sprite.getUnderlyingData(), Project.current.yyExtJson);
		file.writeContent(newSpriteJson);
		file.time = FileWrap.mtimeSync(file.path);
		sprite.unsavedChanges = false;

		return true;
	}

	private function getImagePath(frame: SpriteResourceFrame):String {
		var dir = Path.directory(file.path);
		return Path.join([dir, frame.id + ".png"]);
	}
	
	override public function checkChanges():Void {
		if (!Path.isAbsolute(file.path)) return;
		
		var t1 = FileWrap.mtimeSync(file.path);
		if (t1 != file.time) {
			file.time = t1;
			load(null);
			return;
		}
		
		// if a single frame of the sprite is updated,
		// we might as well just update that element+URL:
		for (frame in framesData) {
			var framePath = frame.path;
			t1 = FileWrap.mtimeSync(framePath);
			if (t1 != frame.importTime) {
				frame.importTime = t1;
				var url = FileWrap.getImageURL(frame.path);
				frame.url = url;
				frame.element.style.backgroundImage = 'url($url)';
				if (currentFrameElement == frame.element) panner.image.src = url;
			}
		}
	}

	private function moveToNextFrame() {
		if (!playingBack) {
			return;
		}
		if ( document.body.contains(element) == false) {
			return;
		}

		adjustCurrentFrame(1);

		var fps;
		if  (sprite.playbackSpeedType == PlaybackSpeedType.FramesPerSecond) {
			fps = sprite.playbackSpeed;
		} else {
			fps = sprite.playbackSpeed * projectRoomSpeed;
		}

		Browser.window.setTimeout(moveToNextFrame, 1000/fps);
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
			saveMeasurement = true;
			boundingBoxMeasurer.start(spriteFrames.map(x -> getImagePath(x)), sprite.bboxTolerance);

			}); // End of measure promise. Purposefully not indented

		});
	}

	private function onSpriteMeasureReady( bbox: SpriteBoundingBox ) {
		sprite.bboxBottom = bbox.bottom;
		sprite.bboxLeft = bbox.left;
		sprite.bboxTop = bbox.top;
		sprite.bboxRight = bbox.right;

		if (saveMeasurement) {
			save();
			saveMeasurement = false;
		}
	
		spriteManipulatorBusy = false;
	}


	private function buildHtml() {
		element.clearInner();
		
		buildOptions();
		bindOptions();

		buildPreview();
	}

	private function bindOptions() {
		/// Header settings
		{
			var title = element.querySelector("#sprite-title");
			title.innerText = sprite.name;
		}
		{
			var widthHeight = element.querySelector("#sprite-width-height");
			var onWidthHeightChanged = (_) -> {
				widthHeight.innerText = '${sprite.width}x${sprite.height}';
			}
			onWidthHeightChanged(null);
			sprite.onHeightChanged.add(onWidthHeightChanged);
			sprite.onWidthChanged.add(onWidthHeightChanged);
		}
		{
			var importButton = element.querySelector("#import-button");
			importButton.addEventListener('click', onSpriteImport);
		}

		/// Origin settings
		function bindToNumberBox(checkboxId: String, startValue: Int, setter: (Int) -> Void, event: EventHandler<Int>) {
			var inputElement:InputElement = cast element.querySelector("#" + checkboxId);
			inputElement.value = Std.string(startValue);
			var update = () -> setter(cast inputElement.valueAsNumber);
			inputElement.addEventListener('change', update);
			inputElement.addEventListener('input', update);
			event.add(newValue -> inputElement.value = Std.string(newValue));
		}

		bindToNumberBox("option-origin-x", 
			sprite.originX,
			newValue -> sprite.originX = newValue,
			sprite.onOriginXChanged
		);
		bindToNumberBox("option-origin-y", 
			sprite.originY,
			newValue -> sprite.originY = newValue,
			sprite.onOriginYChanged
		);
		{
			var originTypeElement:SelectElement = cast element.querySelector("#option-origin-type");
			HtmlTools.setSelectedValue(originTypeElement, Std.string(sprite.originType));
			originTypeElement.addEventListener('change', () -> sprite.setOriginType(cast Std.parseInt(originTypeElement.value)));
			sprite.onOriginTypeChanged.add(x -> HtmlTools.setSelectedValue(originTypeElement, Std.string(sprite.originType)));
		}

		/// Playback speed settings
		bindToNumberBox("option-playback-speed",
			cast sprite.playbackSpeed,
			newValue -> sprite.playbackSpeed = newValue,
			cast sprite.onPlaybackSpeedChanged
		);
		{
			var playbackTypeSelect = cast element.querySelector("#option-playback-speed-type");
			HtmlTools.setSelectedValue(playbackTypeSelect, Std.string(sprite.playbackSpeedType));
			playbackTypeSelect.addEventListener('change', () -> {
				var newValue: PlaybackSpeedType = cast Std.parseInt(playbackTypeSelect.value);
				if (newValue == sprite.playbackSpeedType) {
					return;
				}
				var newSpeed = newValue == PlaybackSpeedType.FramesPerSecond ?
					sprite.playbackSpeed * projectRoomSpeed :
					sprite.playbackSpeed / projectRoomSpeed;

				sprite.playbackSpeed = newSpeed;
				sprite.playbackSpeedType = newValue;
			});
			sprite.onPlaybackSpeedTypeChanged.add(x -> HtmlTools.setSelectedValue(playbackTypeSelect, Std.string(sprite.playbackSpeedType)));
		}

		/// Texture settings
		{
			var textureGroupElement:SelectElement = cast element.querySelector("#option-texture-group");
			for (textureGroup in Project.current.yyTextureGroups) {
				var option = document.createOptionElement();
				option.innerText = textureGroup;
				option.value = textureGroup;
				textureGroupElement.appendChild(option);
			}
			HtmlTools.setSelectedValue(textureGroupElement, sprite.textureGroup);
			textureGroupElement.addEventListener('change', () -> sprite.textureGroup = textureGroupElement.value);
			sprite.onOriginTypeChanged.add(x -> HtmlTools.setSelectedValue(textureGroupElement, sprite.textureGroup));
		}

		function bindToCheckbox(checkboxId: String, startValue: Bool, setter: (Bool) -> Void, event: EventHandler<Bool>) {
			var inputElement: InputElement = cast element.querySelector("#"+checkboxId);
			inputElement.checked = startValue;
			inputElement.addEventListener('change', () -> { setter(inputElement.checked); });
			event.add(newValue -> inputElement.checked = newValue);
		}
		
		bindToCheckbox( "option-tiled-horizontally",
			sprite.tiledHorizontal,
			newValue -> sprite.tiledHorizontal = newValue,
			sprite.onTiledHorizontalChanged
		);
		bindToCheckbox( "option-tiled-vertically",
			sprite.tiledVertical,
			newValue -> sprite.tiledVertical = newValue,
			sprite.onTiledVerticalChanged
		);
		bindToCheckbox( "option-seperate-texture-page",
			sprite.seperateTexturePage,
			newValue -> sprite.seperateTexturePage = newValue,
			sprite.onSeperateTexturePageChanged
		);
		bindToCheckbox( "option-premultiplied-alpha",
			sprite.premultipliedAlpha,
			newValue -> sprite.premultipliedAlpha = newValue,
			sprite.onPremultipliedAlphaChanged
		);
		bindToCheckbox( "option-edge-filtering",
			sprite.edgeFiltering,
			newValue -> sprite.edgeFiltering = newValue,
			sprite.onEdgeFilteringChanged
		);

		/// Bounding box settings
		{
			var modeSelect: SelectElement = cast element.querySelector("#option-bbox-mode");
			HtmlTools.setSelectedValue(modeSelect, Std.string(sprite.bboxMode));
			modeSelect.addEventListener('change', () -> sprite.bboxMode = cast Std.parseInt(modeSelect.value));
			sprite.onBboxModeChanged.add(x -> HtmlTools.setSelectedValue(modeSelect, Std.string(sprite.bboxMode)));
		}
		{
			var typeSelect: SelectElement = cast element.querySelector("#option-bbox-type");
			HtmlTools.setSelectedValue(typeSelect, Std.string(sprite.bboxType));
			typeSelect.addEventListener('change', () -> sprite.bboxType = cast Std.parseInt(typeSelect.value));
			sprite.onBboxTypeChanged.add(x -> HtmlTools.setSelectedValue(typeSelect, Std.string(sprite.bboxType)));
		}

		{
			var sliderElement: InputElement = cast element.querySelector("#option-bbox-tolerance-slider");
			sliderElement.valueAsNumber = sprite.bboxTolerance;
			sprite.onBboxToleranceChanged.add(x -> {
				sliderElement.valueAsNumber = x;
							
				// Hack to trigger event so slider updates
				var event = document.createEvent("HTMLEvents");
				event.initEvent("input", false, true);
				sliderElement.dispatchEvent(event);
			});
			sliderElement.addEventListener('change', () -> sprite.bboxTolerance = cast sliderElement.valueAsNumber);
			HtmlTools.prettifyInputRange( sliderElement );
		}
		
		// Disable some of them depending on what's active
		{
			var numberElements = element.querySelectorAll(".option-bbox-edge");
			var toleranceSlider:InputElement = cast element.querySelector("#option-bbox-tolerance-slider");
			var toleranceBox:InputElement = cast element.querySelector("#option-bbox-tolerance-box");

			var update = _ -> {
				var numbersEnabled = false;
				var toleranceEnabled = false;
				if (sprite.bboxMode == SpriteBboxMode.Automatic) {
					toleranceEnabled = true;
				} else if (sprite.bboxMode == SpriteBboxMode.Manual) {
					numbersEnabled = true;
				}

				toleranceSlider.disabled = !toleranceEnabled;
				toleranceBox.disabled = !toleranceEnabled;
				
				for (numberElement in numberElements) {
					var numberInput: InputElement = cast numberElement;
					numberInput.disabled = !numbersEnabled;
				}
			};

			sprite.onBboxModeChanged.add(update);
			update(null);
		}
		
		bindToNumberBox("option-bbox-tolerance-box", 
			sprite.bboxTolerance,
			newValue -> sprite.bboxTolerance = newValue,
			sprite.onBboxToleranceChanged
		);
		

		bindToNumberBox("option-bbox-left", 
			sprite.bboxLeft,
			newValue -> sprite.bboxLeft = newValue,
			sprite.onBboxLeftChanged
		);
		bindToNumberBox("option-bbox-right", 
			sprite.bboxRight,
			newValue -> sprite.bboxRight = newValue,
			sprite.onBboxRightChanged
		);
		bindToNumberBox("option-bbox-top", 
			sprite.bboxTop,
			newValue -> sprite.bboxTop = newValue,
			sprite.onBboxTopChanged
		);
		bindToNumberBox("option-bbox-bottom", 
			sprite.bboxBottom,
			newValue -> sprite.bboxBottom = newValue,
			sprite.onBboxBottomChanged
		);

	}

	private function buildOptions() {
		var options = document.createDivElement();
		options.id = "sprite-options";
		// Lots of information is duplicated in this tree, like number to origin type etc. I wonder if there's a better way to do it...
		options.innerHTML = SynSugar.xmls(<html>
			<h2 id="sprite-title">SpriteName</h2>
			<p id="sprite-width-height">WIDTHxHEIGHT</p>
			
			<button id="import-button" class="highlighted-button">Import Images</button>
			
			<div>
				<h4>Origin</h4>
				<select id="option-origin-type">
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
				<div>
					<input type="number" id="option-origin-x"/>
					<span>x</span>
					<input type="number" id="option-origin-y"/>
				</div>
			</div>
			
			<div>
				<h4>Playback Speed</h4>
				<div class="one-line">
					<input type="number" id="option-playback-speed" min="0"/>
					<select id="option-playback-speed-type">
						<option value="0">Frames per Second</option>
						<option value="1">Frames per Game Frame</option>
					</select>
				</div>
			</div>

			<div>
				<h4>Texture Settings</h4>
				<div class="one-line">
					<label>Texture Group</label>
					<select id="option-texture-group" class="float-right">
					</select>
				</div>
				<div class="one-line">
					<input type="checkbox" id="option-tiled-horizontally"/>
					<label for="option-tiled-horizontally">Tiled Horizontally</label>
				</div>
				<div class="one-line">
					<input type="checkbox" id="option-tiled-vertically"/>
					<label for="option-tiled-vertically">Tiled Vertically</label>
				</div>
				<div class="one-line">
					<input type="checkbox" id="option-seperate-texture-page"/>
					<label for="option-seperate-texture-page">Seperate Texture Page</label>
				</div>
				<div class="one-line">
					<input type="checkbox" id="option-premultiplied-alpha"/>
					<label for="option-premultiplied-alpha">Premultiplied Alpha</label>
				</div>
				<div class="one-line">
					<input type="checkbox" id="option-edge-filtering"/>
					<label for="option-edge-filtering">Edge Filtered</label>
				</div>
			</div>

			<div>
				<h4>Collision Mask</h4>
				
				<div class="one-line">
					<label>Mode</label>
					<select id="option-bbox-mode" class="float-right">
						<option value="0">Automatic</option>
						<option value="1">Full Image</option>
						<option value="2">Manual</option>
					</select>
				</div>

				<div class="one-line">
					<label>Type</label>
					<select id="option-bbox-type" class="float-right">
						<option value="1">Rectangle</option>
						<option value="5">Rectangle with Rotation</option>
						<option value="2">Ellipse</option>
						<option value="3">Diamond</option>
						<option value="0">Precise</option>
						<option value="4">Precise per Frame</option>
					</select>
				</div>

				<div class="one-line" style="margin-top: 10px">
					<label>Tolerance</label>
					<input type="range" id="option-bbox-tolerance-slider" min="0" max="255" step="1"/>
					<input type="number" id="option-bbox-tolerance-box" min="0" max="255"/>
				</div>
				<div style="margin-top: 10px">
					<div class="one-line">
						<label for="option-bbox-left" class="short-label">Left</label>
						<input id="option-bbox-left" type="number" class="option-bbox-edge"/>
						<label for="option-bbox-right" class="short-label">Right</label>
						<input id="option-bbox-right" type="number" class="option-bbox-edge"/>
					</div>
					<div class="one-line">
						<label for="option-bbox-top" class="short-label">Top</label>
						<input id="option-bbox-top" type="number" class="option-bbox-edge"/>
						<label for="option-bbox-bottom" class="short-label">Bottom</label>
						<input id="option-bbox-bottom" type="number" class="option-bbox-edge"/>
					</div>
				</div>
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
			
			var framesWrapper = document.createDivElement();
			framesWrapper.classList.add("sprite-frame-wrapper");
			
			{
				framesContainer = document.createDivElement();
				framesContainer.classList.add("frames");
				fillFrameContainerContent();
							
				sprite.frames.onFramesReplaced.add( (_) -> fillFrameContainerContent());
				framesWrapper.appendChild(framesContainer);
			}

			{
				var playbackControls = document.createDivElement();
				playbackControls.classList.add("playback-control");
				
				playButton = document.createSpanElement();
				playButton.id = "play-button";
				playButton.innerText = "▶";

				playButton.addEventListener("click", () -> {
					playingBack = !playingBack;
					playButton.innerText = playingBack ? "❚❚" : "▶";
					moveToNextFrame();
				});

				playbackControls.appendChild(playButton);

				framesWrapper.appendChild(playbackControls);
			}


			spriteInfoContainer.appendChild(framesWrapper);
				
			previewContainer.appendChild(spriteInfoContainer);

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
				sprite.frames.onFramesReplaced.add(_ -> {
					panner.image.src = framesData[0].url;
					setCurrentFrameElement(0);
				});
			}
			{
				var spriteBorder = document.createDivElement();
				spriteBorder.style.top = "-1px";
				spriteBorder.style.left = "-1px";
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