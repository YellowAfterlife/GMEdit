(function() {
var ls = window.localStorage;
var mainEl = document.getElementById("main");
var splitters = [];
function syncMain() {
	var mainWidth = window.innerWidth;
	for (var i = 0; i < splitters.length; i++) {
		var sp = splitters[i];
		if (sp.sizer.style.display == "none") continue;
		if (!document.body.contains(sp.sizer)) continue;
		mainWidth -= sp.getWidth();
	}
	mainEl.style.setProperty("--main-width", mainWidth + "px");
}
window.syncSplitterSizes = syncMain;
//
function Splitter(sizer) {
	var target = document.querySelector(sizer.getAttribute("splitter-element"));
	this.target = target;
	this.sizer = sizer;
	var widthVar = sizer.getAttribute("splitter-width-var");
	var isMisc = sizer.id != "splitter-td";
	var parentEl = target.parentElement;
	var lsKey = sizer.getAttribute("splitter-lskey");
	function sync(nw) {
		target.style.width = nw + "px";
		target.style.flex = "0 0 " + nw + "px";
		mainEl.style.setProperty(widthVar, (nw + sizer.offsetWidth) + "px");
		syncMain(nw);
	}
	if (ls) sync(Math.max(0|(ls.getItem(lsKey) || sizer.getAttribute("splitter-default-width")), 50));
	target.style.setProperty("flex-grow", "inherit")
	var sp_mousemove, sp_mouseup, sp_x, sp_y;
	sp_mousemove = function(e) {
		var nx = e.pageX, dx = nx - sp_x; sp_x = nx;
		var ny = e.pageY, dy = ny - sp_y; sp_y = ny;
		var nw = parseFloat(target.style.width) + dx * (target.parentElement.children[0] == target ? 1 : -1);
		if (nw < 50) nw = 50;
		sync(nw);
		if (window.$hxClasses) $hxClasses["ui.ChromeTabs"].impl.layoutTabs()
	};
	sp_mouseup = function(e) {
		document.removeEventListener("mousemove", sp_mousemove);
		document.removeEventListener("mouseup", sp_mouseup);
		mainEl.classList.remove("resizing");
		if (ls) ls.setItem(lsKey, "" + parseFloat(target.style.width));
	};
	sizer.addEventListener("mousedown", function(e) {
		sp_x = e.pageX; sp_y = e.pageY;
		document.addEventListener("mousemove", sp_mousemove);
		document.addEventListener("mouseup", sp_mouseup);
		mainEl.classList.add("resizing");
		e.preventDefault();
	});
	window.addEventListener("resize", function(e) {
		syncMain();
	});
}
Splitter.prototype = {
	getWidth: function() {
		return (parseFloat(this.target.style.width) || this.target.offsetWidth) + this.sizer.offsetWidth;
	}
};
var splitterEls = document.querySelectorAll(".splitter-td");
for (var i = 0; i < splitterEls.length; i++) {
	splitters.push(new Splitter(splitterEls[i]));
}
syncMain();
})();