(function() {
	//
	var popout = document.createElement("div");
	popout.id = "outline-view";
	popout.classList.add("popout-window");
	popout.style.resize = "horizontal";
	//
	var treeview = document.createElement("div")
	treeview.classList.add("treeview");
	popout.appendChild(treeview);
	//
	var treedir = $gmedit["ui.treeview.TreeView"].makeDir("Outline view");
	treedir.classList.add("open");
	var caption = treedir.treeHeader.querySelector("span");
	var currCtr = treedir.treeItems;
	treeview.appendChild(treedir);
	//
	var currEl = null;
	var currOnly = false;
	//
	function currFile() {
		return $gmedit["gml.file.GmlFile"].current;
	}
	//
	var makeItem = $gmedit["ui.treeview.TreeView"].makeItem;
	var navPool = [];
	function makeNav(label, title, nav) {
		var r = navPool.pop();
		if (r) {
			r.querySelector("span").textContent = label;
		} else r = makeItem(label);
		r.title = title;
		if (!!nav.ctx != r.classList.contains("ctx")) {
			r.classList.toggle("ctx");
		}
		r.onclick = function(_) {
			currFile().navigate(nav);
			return false;
		};
		return r;
	}
	//
	var outlineViewID = 0;
	var cache = {};	
	//
	var rxDef = /^(?:#event|#define|#moment|#section|#roomcc)\b\s*(\w+(?::\w+)?)(.*)$/;
	var rxMark = /^\s*((?:#region|\/\/#region)\b\s*(.*))$/
	function reindex(file, pair) {
		if (!pair) pair = cache[file.outlineViewID];
		var el = pair.el;
		var cs = el.children;
		for (var i = 0; i < cs.length; i++) navPool.push(cs[i]);
		el.innerHTML = "";
		if (!file.codeEditor) return;
		//
		var doc = file.codeEditor.session.doc;
		var n = doc.getLength();
		var def = null;
		for (var i = 0; i < n; i++) {
			var mt = rxDef.exec(doc.getLine(i));
			if (mt) {
				def = mt[1];
				el.appendChild(makeNav(def, mt[0], {def:def}));
				continue;
			} else if (mt = rxMark.exec(doc.getLine(i))) {
				el.appendChild(makeNav(mt[2], mt[0], {def:def,ctx:mt[1],ctxAfter:true}));
			}
		}
	}
	//
	function changeTo(file) {
		var id = file.outlineViewID;
		if (id == null) {
			id = ++outlineViewID;
			file.outlineViewID = id;
			var pair = {
				el: document.createElement("div"),
			};
			cache[id] = pair;
			reindex(file, pair);
		}
		var nextEl = cache[id].el;
		if (currEl != nextEl) {
			caption.textContent = file.name;
			if (currEl) currEl.parentElement.removeChild(currEl);
			currCtr.appendChild(nextEl);
			currEl = nextEl;
		}
	}
	//
	var hidden = true;
	function toggle() {
		hidden = !hidden;
		if (hidden) {
			popout.parentElement.removeChild(popout);
		} else {
			document.body.insertBefore(popout, document.querySelector("#preferences-window"));
		}
		if (!hidden) changeTo(currFile());
	}
	function init() {
		AceCommands.add({
			name: "toggleOutlineView",
			exec: function(editor) {
				toggle();
			}
		});
		AceCommands.addToPalette({
			name: "Macro: toggle outline view",
			exec: "toggleOutlineView",
			title: ""
		});
		//
		GMEdit.on("activeFileChange", function(e) {
			if (hidden) return;
			changeTo(e.file);
		});
		GMEdit.on("fileClose", function(e) {
			if (hidden) return;
			var id = e.file.outlineViewID;
			if (id != null) delete cache[id];
		});
		GMEdit.on("fileSave", function(e) {
			if (hidden) return;
			reindex(e.file);
		});
		//
		//toggle();
	}
	GMEdit.register("outline-view", {
		init: init,
		cleanup: function() {
			// todo
		}
	});
})();