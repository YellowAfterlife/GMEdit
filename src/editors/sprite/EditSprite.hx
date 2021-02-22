package editors.sprite;

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

/**
 * This is a big mess as for something that's just an image strip viewer.
 * @author YellowAfterlife
 */
class EditSprite extends Editor {
	var sprite:SpriteResource;
	var panner:Panner;
	var frameCount:Int = 0;
	var currentFrame:Int = 0;
	var currentFrameElement:DivElement;
	var frameURLs:Array<String> = [];
	var framePaths:Array<String> = [];
	var frameElements:Array<DivElement> = [];
	var frameTimes:Array<Float> = [];
	var interval:Null<Int> = null;
	var playbackDelta:Int = 1;
	var recenter = true;
	var animToggle:InputElement;

	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		element.id = "sprite-editor";

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
	override public function destroy():Void {
		super.destroy();
		if (interval != null) {
			window.clearInterval(interval);
			interval = null;
		}
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
		if (frame == null) frame = frameElements[i];
		if (currentFrameElement == frame) return frame;
		currentFrameElement.classList.remove("current");
		frame.classList.add("current");
		currentFrameElement = frame;
		panner.image.src = frameURLs[i];
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

		buildHtml();
	}

	public override function save(): Bool {
		var newSpriteJson = YyJson.stringify(sprite.getUnderlyingData(), Project.current.yyExtJson);
		file.writeContent(newSpriteJson);
		file.changed = false;

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
		}
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

			// A save to save the new path, since we can get stray files otherwise.
			save();
		});
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
	}

	private function buildOptions() {
		var options = document.createDivElement();
		options.id = "sprite-options";
		options.innerHTML = SynSugar.xmls(<html>
			
			<h2>SpriteName</h2>
			<button id="import-button" class="highlighted-button">Import Image</input>
			
		</html>);
		element.appendChild(options);
	}

	private function buildPreview() {
		//
		var previewContainer = document.createDivElement();
		previewContainer.classList.add("resinfo");
		previewContainer.classList.add("sprite");

		var pannerContainer = document.createDivElement();
		pannerContainer.classList.add("sprite-info");

		//
		var frames = document.createDivElement();
		frames.classList.add("frames");
		frameCount = sprite.frames.length;
		frameElements = [];
		frameURLs = [];
		framePaths = [];
		frameTimes = [];
		for (frame in sprite.frames) {
			var framePath = getImagePath(frame);
			var url = FileWrap.getImageURL(framePath);
			var frame = document.createDivElement();
			var index = frameElements.length;
			if (index == 0) {
				currentFrameElement = frame;
				frame.classList.add("current");
			}
			frame.title = "" + index;
			frameElements.push(frame);
			frameURLs.push(url);
			framePaths.push(framePath);
			frameTimes.push(FileWrap.mtimeSync(framePath));
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
			frames.appendChild(frame);
		}
		
		pannerContainer.appendChild(frames);
		
		previewContainer.appendChild(pannerContainer);
		//
		var pan = document.createDivElement();

		var imgCtr = document.createDivElement();
		recenter = true;

		var img = document.createImageElement();
		img.onload = function(_) {
			img.onload = null;
			checkRecenter();
		}
		var framePath = getImagePath(sprite.frames[0]);
		img.src = FileWrap.getImageURL(framePath);
		imgCtr.appendChild(img);


		var spriteBorder = document.createDivElement();
		spriteBorder.classList.add("panner-element");
		spriteBorder.style.width = '${sprite.width}px';
		spriteBorder.style.height = '${sprite.height}px';
		spriteBorder.style.border = "1px solid rgba(255, 255, 255, 0.5)";
		imgCtr.appendChild(spriteBorder);


		pan.appendChild(imgCtr);
		panner = new Panner(pan, imgCtr);
		previewContainer.appendChild(pan);
		//

		element.appendChild(previewContainer);
	}
}
