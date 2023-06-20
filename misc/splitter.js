(function() {
var mainEl = document.getElementById("main");
var splitters = [];
var electron, fs, configPath;
if (window.require) {
	electron = require("electron");
	fs = require("fs");
	var remote = electron.remote;
	if (remote == null) remote = require("@electron/remote");
	configPath = remote.app.getPath("userData") + "/GMEdit/session/splitter.json";
}
var conf = null;
function initConf() {
	if (conf == null && window["$gmedit"]) {
		conf = new $gmedit["electron.ConfigFile"]("session", "splitter");
	}
}

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
//
function Splitter(sizer) {
	initConf();
	var q = this;
	var target = document.querySelector(sizer.getAttribute("splitter-element"));
	this.target = target;
	this.sizer = sizer;
	this.widthVar = sizer.getAttribute("splitter-width-var");
	this.setVars = !!this.widthVar;
	this.minWidth = 0|(sizer.getAttribute("splitter-min-width")||50);
	this.updateTabs = sizer.getAttribute("splitter-update-tabs");
	this.isMisc = sizer.id != "splitter-td";
	this.parentEl = target.parentElement;
	this.lsKey = sizer.getAttribute("splitter-lskey");
	target.style.setProperty("flex-grow", "inherit");
	//
	var w = null;
	if (conf) {
		conf.sync();
		if (conf.data == null) conf.data = {};
		var sub = conf.data[this.lsKey];
		if (sub) w = sub.width;
	} else try {
		var json_str = fs ? fs.readFileSync(configPath) : localStorage.getItem("session/splitter");
		var json = JSON.parse(json_str);
		var sub = json[this.lsKey];
		if (sub) w = sub.width;
	} catch (x) {
		//
	}
	this.setWidth(Math.max(0|(w || sizer.getAttribute("splitter-default-width")), this.minWidth));
	//
	var sp_mousemove, sp_mouseup, sp_x, sp_y;
	sp_mousemove = function(e) {
		var nx = e.pageX, dx = nx - sp_x; sp_x = nx;
		var ny = e.pageY, dy = ny - sp_y; sp_y = ny;
		var nw = parseFloat(q.target.style.width) + dx * (q.target.parentElement.children[0] == q.target ? 1 : -1);
		if (nw < q.minWidth) nw = q.minWidth;
		q.setWidth(nw);
		if (q.updateTabs && window.$gmedit) $gmedit["ui.ChromeTabs"].impl.layoutTabs()
		
		var e = new CustomEvent("resize");
		e.initEvent("resize");
		window.dispatchEvent(e);
	};
	sp_mouseup = function(e) {
		document.removeEventListener("mousemove", sp_mousemove);
		document.removeEventListener("mouseup", sp_mouseup);
		mainEl.classList.remove("resizing");
		var w = parseFloat(q.target.style.width);
		// save
		initConf();
		if (conf) {
			conf.sync();
			if (conf.data == null) conf.data = {};
			var sub = conf.data[q.lsKey];
			if (sub == null) sub = conf.data[q.lsKey] = {};
			sub.width = w;
			conf.flush();
		}
	};
	sizer.addEventListener("mousedown", function(e) {
		sp_x = e.pageX; sp_y = e.pageY;
		document.addEventListener("mousemove", sp_mousemove);
		document.addEventListener("mouseup", sp_mouseup);
		mainEl.classList.add("resizing");
		e.preventDefault();
	});
}
Splitter.syncMain = syncMain;
Splitter.splitters = splitters;
Splitter.prototype = {
	getWidth: function() {
		var targetWidth = this.target.offsetWidth;
		return (targetWidth > 0 ? (parseFloat(this.target.style.width) || targetWidth) : 0) + this.sizer.offsetWidth;
	},
	setWidth: function(nw) {
		this.target.style.width = nw + "px";
		this.target.style.flex = "0 0 " + nw + "px";
		if (this.setVars) {
			mainEl.style.setProperty(this.widthVar, (nw + this.sizer.offsetWidth) + "px");
			syncMain(nw);
		}
	}
};
window.GMEdit_Splitter = Splitter;
var splitterEls = document.querySelectorAll(".splitter-td");
for (var i = 0; i < splitterEls.length; i++) {
	var sp = new Splitter(splitterEls[i])
	if (sp.setVars) splitters.push(sp);
}
window.addEventListener("resize", function(e) {
	syncMain();
});
syncMain();
})();