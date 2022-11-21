package editors.sprite;

import editors.Editor;
import electron.FileSystem;
import electron.FileWrap;
import gml.Project;
import gml.file.GmlFile;
import gml.file.GmlFileExtra;
import gmx.SfGmx;
import haxe.io.Path;
import js.html.DivElement;
import js.html.ImageElement;
import js.html.InputElement;
import js.html.KeyboardEvent;
import tools.NativeString;
import file.kind.yy.KYySprite;
import file.kind.gmx.KGmxSprite;
using tools.HtmlTools;
import yy.YySprite;
import Main.document;
import Main.window;
import electron.Shell;

/**
 * This is a big mess as for something that's just an image strip viewer.
 * @author YellowAfterlife
 */
class PreviewSprite extends Editor {
	var image:ImageElement;
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
		element.classList.add("resinfo");
		element.classList.add("sprite");
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
	function getData1(data:String):PreviewSpriteData {
		var d = new PreviewSpriteData();
		#if !gmedit.no_gmx
		var pj = Project.current;
		var q:SfGmx = FileWrap.readGmxFileSync(file.path);
		d.xorig = q.findFloat("xorig");
		d.yorig = q.findFloat("yorigin");
		d.width = q.findFloat("width");
		d.height = q.findFloat("height");
		for (frame in q.find("frames").findAll("frame")) {
			var frel = "sprites/" + frame.text;
			var url = pj.getImageURL(frel);
			d.frameURLs.push(url);
			d.framePaths.push(frel);
		}
		d.frameCount = d.frameURLs.length;
		#end
		return d;
	}
	function getData2(q:YySprite):PreviewSpriteData {
		var d = new PreviewSpriteData();
		d.xorig = q.xorig;
		d.yorig = q.yorig;
		d.width = q.width;
		d.height = q.height;
		d.playbackLegacy = q.playbackSpeedType != 0;
		d.playbackSpeed = q.playbackSpeed;
		var dir = Path.directory(file.path);
		for (frame in q.frames) {
			var fid = frame.name;
			if (fid == null) fid = frame.id;
			var frel = Path.join([dir, fid + ".png"]);
			var url = FileWrap.getImageURL(frel);
			d.frameURLs.push(url);
			d.framePaths.push(frel);
		}
		d.frameCount = d.frameURLs.length;
		return d;
	}
	function setCurrentFrameElement(i:Int, ?frame:DivElement):DivElement {
		if (frame == null) frame = frameElements[i];
		if (currentFrameElement == frame) return frame;
		currentFrameElement.classList.remove("current");
		frame.classList.add("current");
		currentFrameElement = frame;
		image.src = frameURLs[i];
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
		var d:PreviewSpriteData = v2 ? getData2(data) : getData1(data);
		element.clearInner();
		//
		var ctr = document.createDivElement();
		ctr.classList.add("sprite-info");
		var info = document.createDivElement();
		info.classList.add("sprite-info-text");
		info.appendChild(document.createTextNode(d.width + "x" + d.height
			+ "; " + d.xorig + "," + d.yorig));
		info.appendChild(document.createBRElement());
		info.appendChild(document.createTextNode(d.frameCount + " frame" + (d.frameCount != 1 ? "s" : "")));
		if (d.frameCount > 1) {
			info.appendChild(document.createBRElement());
			var toggle:InputElement, mult:InputElement, fps:InputElement;
			toggle = document.createInputElement();
			toggle.type = "checkbox";
			toggle.title = "Toggle playback";
			animToggle = toggle;
			info.appendChild(toggle);
			//
			mult = document.createInputElement();
			mult.style.width = "2em";
			mult.value = "1";
			mult.title = "Playback speed multiplier";
			info.appendChild(mult);
			fps = document.createInputElement();
			if (d.playbackLegacy) {
				info.appendChild(document.createTextNode("x"));
				fps.style.width = "2em";
				fps.value = "" + Project.current.getFrameRate();
				fps.title = "Target framerate";
				info.appendChild(fps);
			} else {
				info.appendChild(document.createTextNode("x"));
				fps.value = "1";
			}
			//
			function nextFrame() {
				adjustCurrentFrame(playbackDelta);
			}
			function syncInterval(_) {
				if (interval != null) window.clearInterval(interval);
				if (toggle.checked) {
					//
					var tx = Std.parseFloat(mult.value);
					if (Math.isNaN(tx)) {
						tx = 0;
						mult.classList.add("error");
					} else mult.classList.remove("error");
					//
					var tf = 1.;
					if (d.playbackLegacy) {
						tf = Std.parseFloat(fps.value);
						if (Math.isNaN(tf)) {
							tf = 0;
							fps.classList.add("error");
						} else fps.classList.remove("error");
					}
					//
					if (tx == 0 || tf == 0 || d.playbackSpeed == 0) {
						interval = null;
					} else {
						var s = d.playbackSpeed * tx * tf;
						if (s < 0) {
							playbackDelta = -1;
							s = -s;
						} else playbackDelta = 1;
						var t = Std.int(1000 / s);
						interval = window.setInterval(nextFrame, t);
					}
				} else interval = null;
			}
			var mult_val = mult.value;
			var fps_val = fps.value;
			var toggle_val = toggle.checked;
			var autosync_can = true;
			function autosync_1() {
				autosync_can = true;
				syncInterval(null);
			}
			function autosync() {
				if (mult.value == mult_val
				&& fps.value == fps_val
				&& toggle.checked == toggle_val) return;
				mult_val = mult.value;
				fps_val = fps.value;
				toggle_val = toggle.checked;
				if (autosync_can) {
					autosync_can = false;
					window.setTimeout(autosync_1, 50);
				}
			}
			toggle.onchange = autosync;
			mult.onchange = autosync;
			mult.onkeydown = autosync;
			mult.onkeyup = autosync;
			fps.onchange = autosync;
			fps.onkeydown = autosync;
			fps.onkeyup = autosync;
		};
		//
		var frames = document.createDivElement();
		frames.classList.add("frames");
		frameCount = d.frameCount;
		frameElements = [];
		frameURLs = [];
		framePaths = [];
		frameTimes = [];
		for (i in 0 ... d.frameCount) {
			var url = d.frameURLs[i];
			var framePath = d.framePaths[i];
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
			if (d.width > 48 || d.height > 48) {
				frame.style.backgroundSize = "contain";
			}
			// something isn't right here, why do we only need to escape this here of all places?
			url = StringTools.replace(url, " ", "%20");
			//
			frame.style.backgroundImage = 'url($url)';
			if (d.width <= 24 && d.height <= 24) {
				frame.style.backgroundSize = '${d.width * 2}px ${d.height * 2}px';
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
		ctr.appendChild(info);
		ctr.appendChild(frames);
		element.appendChild(ctr);
		//
		var pan = document.createDivElement();
		pan.style.flex = "1";
		var img = document.createImageElement();
		image = img;
		recenter = true;
		img.onload = function(_) {
			img.onload = null;
			checkRecenter();
		}
		img.src = d.frameURLs[0];
		pan.appendChild(img);
		panner = new Panner(pan, img);
		element.appendChild(pan);
		//
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
}
class PreviewSpriteData {
	public var xorig:Float;
	public var yorig:Float;
	public var width:Float;
	public var height:Float;
	public var frameCount:Int = 0;
	public var frameURLs:Array<String> = [];
	public var framePaths:Array<String> = [];
	public var playbackSpeed = 1.;
	public var playbackLegacy = true;
	public function new() {
		
	}
}
