package editors;

import editors.Editor;
import electron.FileWrap;
import gml.Project;
import gml.file.GmlFile;
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

/**
 * This is a big mess as for something that's just an image strip viewer.
 * @author YellowAfterlife
 */
class EditSprite extends Editor {
	var image:ImageElement;
	var panner:Panner;
	var frameCount:Int = 0;
	var currentFrame:Int = 0;
	var currentFrameElement:DivElement;
	var frameURLs:Array<String> = [];
	var frameElements:Array<DivElement> = [];
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
	function getData1(data:String):EditSpriteData {
		var d = new EditSpriteData();
		var pj = Project.current;
		var q:SfGmx = FileWrap.readGmxFileSync(file.path);
		d.xorig = q.findFloat("xorig");
		d.yorig = q.findFloat("yorigin");
		d.width = q.findFloat("width");
		d.height = q.findFloat("height");
		for (frame in q.find("frames").findAll("frame")) {
			d.frames.push(pj.getImageURL("sprites/" + frame.text));
		}
		return d;
	}
	function getData2(q:YySprite):EditSpriteData {
		var d = new EditSpriteData();
		d.xorig = q.xorig;
		d.yorig = q.yorig;
		d.width = q.width;
		d.height = q.height;
		d.playbackLegacy = q.playbackSpeedType != 0;
		d.playbackSpeed = q.playbackSpeed;
		var dir = Path.directory(file.path);
		var isAbs = Path.isAbsolute(dir);
		var pj = Project.current;
		for (frame in q.frames) {
			var frel = Path.join([dir, frame.id + ".png"]);
			d.frames.push(isAbs ? "file:///" + frel : pj.getImageURL(frel));
		}
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
		var d:EditSpriteData = v2 ? getData2(data) : getData1(data);
		element.clearInner();
		//
		var ctr = document.createDivElement();
		ctr.classList.add("sprite-info");
		var info = document.createDivElement();
		info.classList.add("sprite-info-text");
		info.appendChild(document.createTextNode(d.width + "x" + d.height
			+ "; " + d.xorig + "," + d.yorig));
		info.appendChild(document.createBRElement());
		info.appendChild(document.createTextNode(d.frames.length + " frame" + (d.frames.length != 1 ? "s" : "")));
		if (d.frames.length > 1) {
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
		frameCount = d.frames.length;
		frameElements = [];
		frameURLs = [];
		for (url in d.frames) {
			var frame = document.createDivElement();
			var index = frameElements.length;
			if (index == 0) {
				currentFrameElement = frame;
				frame.classList.add("current");
			}
			frame.title = "" + index;
			frameElements.push(frame);
			frameURLs.push(url);
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
		img.src = d.frames[0];
		pan.appendChild(img);
		panner = new Panner(pan, img);
		element.appendChild(pan);
		//
	}
}
class EditSpriteData {
	public var xorig:Float;
	public var yorig:Float;
	public var width:Float;
	public var height:Float;
	public var frames:Array<String> = [];
	public var playbackSpeed = 1.;
	public var playbackLegacy = true;
	public function new() {
		
	}
}
