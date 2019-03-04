(function() {
	//
	var popout = false; // show a popout instead of a sidebar
	var currOnly = false; // original idea (only show the current file)
	var lightDef = false; // poll current definition from Ace status bar
	//
	// items (definitions)
	var rxDef = /^(?:#event|#define|#moment|#section|#roomcc)\b\s*(\w+(?::\w+)?)(.*)$/;
	// subitems (regions/landmarks)
	var rxMark = /^\s*((?:#region|\/\/#region|\/\/#mark)\b\s*(.*))$/;
	//
	var outer = document.createElement("div");
	outer.id = "outline-view";
	if (popout) {
		outer.classList.add("outer-window");
		outer.style.resize = "horizontal";
	}
	//
	var treeview = document.createElement("div")
	treeview.classList.add("treeview");
	outer.appendChild(treeview);
	//
	var currEl = null;
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
	var escapeProp = $gmedit["tools.NativeString"].escapeProp;
	function updateCurrentDefSave(file) {
		var ctr = file.outlineView;
		if (!ctr) return;
		var curr = treeview.querySelector(".outline-current-file .outline-current-def");
		if (curr) curr.classList.remove("outline-current-def");
		//
		var query = null, itemq = null;
		var session = file.codeEditor.session;
		for (var row = session.selection.lead.row; row >= 0; row--) {
			var rowText = session.getLine(row);
			var mt = rxDef.exec(rowText);
			if (mt != null) {
				query = '.item[outline-def="'+escapeProp(mt[1])+'"]';
				break;
			}
			if (!itemq) {
				mt = rxMark.exec(rowText);
				if (mt) itemq = '[title="'+escapeProp(mt[1])+'"]';
			}
		}
		//
		if (itemq) query += itemq;
		var item = ctr.querySelector(query);
		if (item) item.classList.add("outline-current-def");
	}
	function updateCurrentDef(file, ctr, def) {
		var curr = treeview.querySelector(".outline-current-file .outline-current-def");
		if (curr) curr.classList.remove("outline-current-def");
		if (!def) return;
		//
		var query = '.item[outline-def="'+escapeProp(def)+'"]';
		var item = null;
		if (ctr.querySelector(query+'.ctx')) {
			var session = file.codeEditor.session;
			for (var row = session.selection.lead.row; row >= 0; row--) {
				var rowText = session.getLine(row);
				var mt = rxDef.exec(rowText);
				if (mt != null) break;
				mt = rxMark.exec(rowText);
				if (mt) {
					item = ctr.querySelector(query+'[title="'+escapeProp(mt[1])+'"]');
					if (item) break;
				}
			}
		}
		//
		if (!item) item = ctr.querySelector(query);
		if (item) item.classList.add("outline-current-def");
	}
	//
	var makeItem = $gmedit["ui.treeview.TreeView"].makeItem;
	var navPool = [];
	function makeNav(file, label, title, evt, nav) {
		var r = navPool.pop();
		if (r) {
			r.querySelector("span").textContent = label;
		} else r = makeItem(label);
		r.setAttribute("outline-event", evt||"");
		r.setAttribute("outline-def", nav.def);
		r.title = title;
		// items navigating to inside of events get a "ctx" class for indication
		if (!!nav.ctx != r.classList.contains("ctx")) {
			r.classList.toggle("ctx");
		}
		r.onclick = function(_) {
			function finish() {
				file.navigate(nav);
				updateCurrentDef(file, file.outlineView, nav.def);
				aceEditor.scrollToLine(aceEditor.selection.lead.row);
				aceEditor.focus();
			}
			if (currFile() != file) {
				if (activate(file)) {
					finish();
					//setTimeout(finish);
				}
			} else finish();
			return false;
		};
		return r;
	}
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
				var evt = mt[0].startsWith("#e") ? def : null;
				el.appendChild(makeNav(file, txt, txt, evt, {
					def: def,
					showAtTop: true
				}));
				continue;
			}
			else if (mt = rxMark.exec(doc.getLine(i))) {
				el.appendChild(makeNav(file, mt[2], mt[0], null, {
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
	function changeTo_post(file) {
		var curr = treeview.querySelector(".outline-current-file");
		if (curr) curr.classList.remove("outline-current-file");
		if (file.outlineView) file.outlineView.classList.add("outline-current-file");
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
		changeTo_post(file);
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
		updateCurrentDefSave(e.file);
	}
	function onTabsReorder(e) {
		syncAll(e.target.tabEls);
	}
	// update current subitem on editor navigation
	var onUpdate_scheduled = false;
	function onUpdate() {
		onUpdate_scheduled = false;
		var ctxEl = document.querySelector(".ace_status-hint .context");
		var ctx = (ctxEl && ctxEl.style.display != "none") ? ctxEl.innerText : null;
		var ctr = treeview.querySelector('.outline-current-file');
		updateCurrentDef(currFile(), ctr, ctx);
	}
	function onUpdate_schedule() {
		if (onUpdate_scheduled) return;
		onUpdate_scheduled = true;
		setTimeout(onUpdate, 120);
	}
	//
	var hidden = true;
	function toggle() {
		hidden = !hidden;
		if (!hidden) {
			if (popout) {
				document.body.insertBefore(outer, document.querySelector("#preferences-window"));
			} else {
				GMEdit.sidebar.add("Outline View", outer);
				GMEdit.sidebar.set("Outline View");
			}
			GMEdit.on("activeFileChange", onFileChange);
			GMEdit.on("fileClose", onFileClose);
			GMEdit.on("fileSave", onFileSave);
			GMEdit.on("tabsReorder", onTabsReorder);
			aceEditor.on("changeStatus", onUpdate_schedule);
			aceEditor.on("changeSelection", onUpdate_schedule);
			aceEditor.on("keyboardActivity", onUpdate_schedule);
		} else {
			if (popout) {
				outer.parentElement.removeChild(outer);
			} else {
				GMEdit.sidebar.remove("Outline View", outer);
			}
			GMEdit.off("activeFileChange", onFileChange);
			GMEdit.off("fileClose", onFileClose);
			GMEdit.off("fileSave", onFileSave);
			GMEdit.off("tabsReorder", onTabsReorder);
			aceEditor.off("changeStatus", onUpdate_schedule);
			aceEditor.off("changeSelection", onUpdate_schedule);
			aceEditor.off("keyboardActivity", onUpdate_schedule);
		}
		if (!hidden) {
			if (currOnly) {
				changeTo(currFile());
			} else {
				syncAll();
				changeTo_post(currFile());
				onUpdate_schedule();
			}
		}
	}
	function init() {
		AceCommands.add({
			name: "toggleOutlineView",
			//bindKey: "Ctrl-Shift-O",
			exec: function(editor) {
				toggle();
				localStorage.setItem("outline-view-hide", hidden);
			}
		});
		AceCommands.addToPalette({
			name: "Toggle outline view",
			exec: "toggleOutlineView",
			title: ""
		});
		if (localStorage.getItem("outline-view-hide") != "true") toggle();
	}
	GMEdit.register("outline-view", {
		init: init,
		cleanup: function() {
			// todo
		}
	});
})();