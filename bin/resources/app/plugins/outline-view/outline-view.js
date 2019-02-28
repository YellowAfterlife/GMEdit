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
	var currEl = null;
	var currOnly = false;
	//
	function currFile() {
		return $gmedit["gml.file.GmlFile"].current;
	}
	//
	var makeItem = $gmedit["ui.treeview.TreeView"].makeItem;
	var navPool = [];
	function activate(file) {
		var tabs = document.querySelectorAll(".chrome-tab");
		for (var i = 0; i < tabs.length; i++) {
			if (tabs[i].gmlFile == file) {
				tabs[i].click();
				return tabs[i];
			}
		}
		return null;
	}
	function makeNav(file, label, title, nav) {
		var r = navPool.pop();
		if (r) {
			r.querySelector("span").textContent = label;
		} else r = makeItem(label);
		r.title = title;
		if (!!nav.ctx != r.classList.contains("ctx")) {
			r.classList.toggle("ctx");
		}
		r.onclick = function(_) {
			if (currFile() != file) {
				if (activate(file)) {
					setTimeout(function() {
						file.navigate(nav);
					});
				}
			} else file.navigate(nav);
			return false;
		};
		return r;
	}
	//
	var rxDef = /^(?:#event|#define|#moment|#section|#roomcc)\b\s*(\w+(?::\w+)?)(.*)$/;
	var rxMark = /^\s*((?:#region|\/\/#region)\b\s*(.*))$/;
	function reindex(file) {
		var ov = file.outlineView;
		var el = ov.treeItems;
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
				var txt = def;
				if (def != "properties") {
					var tail = mt[2].trim();
					if (tail) txt += " ➜ " + tail;
				}
				el.appendChild(makeNav(file, txt, txt, {def:def}));
				continue;
			} else if (mt = rxMark.exec(doc.getLine(i))) {
				el.appendChild(makeNav(file, mt[2], mt[0], {def:def,ctx:mt[1],ctxAfter:true}));
			}
		}
		var th = ov.treeHeader;
		if ((el.children.length == 0) != th.classList.contains("item")) {
			ov.classList.toggle("dir");
			th.classList.toggle("item");
		}
	}
	//
	function createFor(file) {
		var dir = $gmedit["ui.treeview.TreeView"].makeDir(file.name);
		dir.classList.add("open");
		dir.treeHeader.addEventListener("click", function(_) {
			if (dir.classList.contains("dir")) {
				dir.classList.toggle("open");
			} else activate(file);
		});
		file.outlineView = dir;
		reindex(file);
	}
	function syncAll(tabEls) {
		if (tabEls == null) tabEls = $gmedit["ui.ChromeTabs"].impl.tabEls;
		treeview.innerHTML = "";
		for (var i = 0; i < tabEls.length; i++) {
			var tabEl = tabEls[i];
			var file = tabEl.gmlFile;
			if (!file) continue;
			if (!file.outlineView) createFor(file);
			treeview.appendChild(file.outlineView);
		}
	}
	function changeTo(file) {
		if (!file.outlineView) {
			createFor(file);
			if (!currOnly) syncAll();
		}
		if (currOnly) {
			var nextEl = file.outlineView;
			if (currEl != nextEl) {
				if (currEl) currEl.parentElement.removeChild(currEl);
				treeview.appendChild(nextEl);
				currEl = nextEl;
			}
		} else {
			var ov = file.outlineView;
			if (ov.scrollIntoViewIfNeeded) {
				ov.scrollIntoViewIfNeeded();
			} else ov.scrollIntoView();
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
		if (!hidden) {
			if (currOnly) {
				changeTo(currFile());
			} else syncAll();
		}
	}
	function init() {
		AceCommands.add({
			name: "toggleOutlineView",
			exec: function(editor) {
				toggle();
			}
		});
		AceCommands.addToPalette({
			name: "Toggle outline view",
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
		GMEdit.on("tabsReordered", function(e) {
			if (hidden) return;
			syncAll(e.target.tabEls);
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