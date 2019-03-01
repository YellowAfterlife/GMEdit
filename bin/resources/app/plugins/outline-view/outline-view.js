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
	var currOnly = false; // original idea (only show the current file in popout)
	//
	function currFile() {
		return $gmedit["gml.file.GmlFile"].current;
	}
	// maybe this should be a "built-in" function instead
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
	//
	var makeItem = $gmedit["ui.treeview.TreeView"].makeItem;
	var navPool = [];
	function makeNav(file, label, title, nav) {
		var r = navPool.pop();
		if (r) {
			r.querySelector("span").textContent = label;
		} else r = makeItem(label);
		r.title = title;
		// items navigating to inside of events get a "ctx" class for indication
		if (!!nav.ctx != r.classList.contains("ctx")) {
			r.classList.toggle("ctx");
		}
		r.onclick = function(_) {
			function finish() {
				file.navigate(nav);
				aceEditor.scrollToLine(aceEditor.selection.lead.row);
				aceEditor.focus();
			}
			if (currFile() != file) {
				if (activate(file)) {
					setTimeout(finish);
				}
			} else finish();
			return false;
		};
		return r;
	}
	// items (definitions)
	var rxDef = /^(?:#event|#define|#moment|#section|#roomcc)\b\s*(\w+(?::\w+)?)(.*)$/;
	// subitems (regions/landmarks)
	var rxMark = /^\s*((?:#region|\/\/#region|\/\/#mark)\b\s*(.*))$/;
	function reindex(file) {
		var ov = file.outlineView;
		var el = ov.treeItems;
		if (!file.codeEditor) return;
		// pool up the existing items:
		var cs = el.children;
		for (var i = 0; i < cs.length; i++) navPool.push(cs[i]);
		el.innerHTML = "";
		// now we add items for events/regions
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
					if (tail) txt += " ➜ " + tail; // narrow space, arrow, narrow space
				}
				el.appendChild(makeNav(file, txt, txt, {
					def: def,
					showAtTop: true
				}));
				continue;
			}
			else if (mt = rxMark.exec(doc.getLine(i))) {
				el.appendChild(makeNav(file, mt[2], mt[0], {
					def: def,
					ctx: mt[1],
					ctxAfter: true,
					showAtTop: true
				}));
			}
		}
		// in what is no less than a bit of a hack, for items with no children
		// we shall simply untag .dir from container, and tag the header with .item
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
			// mirroring above, clicking a childless item should open it instead
			if (dir.classList.contains("dir")) {
				dir.classList.toggle("open");
			} else activate(file);
		});
		file.outlineView = dir;
		reindex(file);
	}
	// updates the panel to contain treeviews of active tabs and in correct order
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
	function onFileChange(e) {
		changeTo(e.file);
	}
	function onFileClose(e) {
		syncAll();
	}
	function onFileSave(e) {
		reindex(e.file);
	}
	function onTabsReorder(e) {
		syncAll(e.target.tabEls);
	}
	//
	var hidden = true;
	function toggle() {
		hidden = !hidden;
		if (hidden) {
			popout.parentElement.removeChild(popout);
			GMEdit.off("activeFileChange", onFileChange);
			GMEdit.off("fileClose", onFileClose);
			GMEdit.off("fileSave", onFileSave);
			GMEdit.off("tabsReorder", onTabsReorder);
		} else {
			document.body.insertBefore(popout, document.querySelector("#preferences-window"));
			GMEdit.on("activeFileChange", onFileChange);
			GMEdit.on("fileClose", onFileClose);
			GMEdit.on("fileSave", onFileSave);
			GMEdit.on("tabsReorder", onTabsReorder);
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
			//bindKey: "Ctrl-Shift-O",
			exec: function(editor) {
				toggle();
			}
		});
		AceCommands.addToPalette({
			name: "Toggle outline view",
			exec: "toggleOutlineView",
			title: ""
		});
		//toggle();
	}
	GMEdit.register("outline-view", {
		init: init,
		cleanup: function() {
			// todo
		}
	});
})();