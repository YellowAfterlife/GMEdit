package editors;
import js.html.Element;
import js.Browser;
import js.html.DivElement;
import js.html.ImageElement;
import js.html.MouseEvent;

/**
 * As seen in IMGXIS and YYTextureView
 * @author YellowAfterlife
 */
class Panner {
	public var pan:{ x:Float, y:Float, z:Float };
	public var mult:Float = 1;
	public var ctr:DivElement;
	public var image:ImageElement;
	private var rootElement:Element;
	private var zoomed:Bool = null;
	private var mouseX:Float = 0;
	private var mouseY:Float = 0;
	private var mouseDown:Bool = false;
	public function new(el:DivElement, rootElement: Element) {
		ctr = el;
		ctr.classList.add("panner");
		if (rootElement.tagName == "IMG") {
			image = cast rootElement;
		} else {
			image = cast rootElement.querySelector("IMG");
		}
		this.rootElement = rootElement;
		pan = { x: 0, y: 0, z: 0 };
		el.addEventListener("mousedown", onmousedown);
		el.addEventListener("mousewheel", onmousewheel);
		el.addEventListener("DOMMouseScroll", onmousewheel);
		ctr.tabIndex = 0;
	}
	//
	public function update() {
		var pz = (mult >= 1);
		if (pz != zoomed) {
			zoomed = pz;
			if (pz) {
				ctr.classList.add("zoomed");
			} else ctr.classList.remove("zoomed");
		}
		ctr.setAttribute("data-zoom", Math.round(mult * 100) + "%");
		rootElement.style.transform = 'matrix($mult,0,0,$mult,${-pan.x},${-pan.y})';
	}
	public function forceUpdate() {
		mult = Math.pow(2, pan.z);
		zoomed = null;
		update();
	}
	public function zoomTo(zx:Float, zy:Float, d:Float) {
		var prev = mult;
		pan.z += d;
		mult = Math.pow(2, pan.z);
		var f = mult / prev;
		//
		pan.x = (zx + pan.x) * f - zx;
		pan.y = (zy + pan.y) * f - zy;
		update();
	}
	//
	function onmousemove(e:MouseEvent) {
		var ox = mouseX;
		mouseX = e.pageX;
		var dx = mouseX - ox;
		//
		var oy = mouseY;
		mouseY = e.pageY;
		var dy = mouseY - oy;
		//
		if (mouseDown) {
			pan.x -= (mouseX - ox);
			pan.y -= (mouseY - oy);
			update();
		}
	}
	function onmousedown(e:MouseEvent) {
		ctr.focus();
		onmousemove(e);
		if (e.which != 3) {
			ctr.focus();
			e.preventDefault();
			mouseDown = true;
		}
		Browser.document.addEventListener("mouseup", onmouseup);
		Browser.document.addEventListener("mousemove", onmousemove);
	}
	function onmouseup(e:MouseEvent) {
		onmousemove(e);
		mouseDown = false;
		Browser.document.removeEventListener("mouseup", onmouseup);
		Browser.document.removeEventListener("mousemove", onmousemove);
	}
	function onmousewheel(e:MouseEvent) {
		var d:Float = Reflect.field(e, "wheelDelta");
		if (d == null) d = -e.detail;
		d = (d < 0 ? -1 : d > 0 ? 1 : 0) * 0.5;
		var mx = e.offsetX;
		var my = e.offsetY;
		zoomTo(mx, my, d);
	}
	//
	public function recenter():Void {
		var cw = ctr.offsetWidth;
		var ch = ctr.offsetHeight;
		if (cw <= 0 || ch <= 0) return;
		var qw:Float = image.width;
		var qh:Float = image.height;

		if (qw <= 0 || qh <= 0) return;
		var z = 0;
		while (qw < cw && qh < ch) {
			if (qw * 2 < cw && qh * 2 < ch) {
				qw *= 2; qh *= 2; z += 1;
			} else break;
		}
		while (qw > cw || qh > ch) {
			qw /= 2; qh /= 2; z -= 1;
		}
		pan.z = z;
		pan.x = -Std.int((cw - qw) / 2);
		pan.y = -Std.int((ch - qh) / 2);
		forceUpdate();
	}
}
