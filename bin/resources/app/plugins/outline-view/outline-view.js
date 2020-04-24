(function() {
	function setc(el, name, on) {
		if (el.classList.contains(name) != !!on) {
			el.classList.toggle(name);
		}
	}
	function seta(el, attr, val) {
		if (val != null) {
			el.setAttribute(attr, val);
		} else el.removeAttribute(attr);
	}
	//
	var popout = false; // show a popout instead of a sidebar
	var currOnly = false; // original idea (only show the current file)
	var showAtTop = true;
	//
	var escapeProp = $gmedit["tools.NativeString"].escapeProp;
	var modeMap = {
		"ace/mode/gml": (function() {
			var rxDef = /^(?:(#event)|#define|#moment|#section|#roomcc|function)\b\s*(\w+(?::\w+)?)(.*)$/;
			var rxPush = /^\s*((?:#region|\/\/#region)\b\s*(.*))$/;
			var rxPop = /^\s*(?:#endregion|\/\/#endregion)\b/;
			var rxMark = /^\s*((?:\/\/#mark|#section)\b\s*(.*))$/;
			var rxCtx = /^\s*((?:#region|\/\/#region|\/\/#mark)\b.*)$/
			function update(file, pos) {
				var def = pos.def, row = pos.row;
				var ctx = null, ctxRow = null;
				var doc = file.codeEditor.session.doc;
				for (; row >= 0; row--) {
					var rowText = doc.getLine(row), mt;
					if (mt = rxDef.exec(rowText)) { def = mt[2]; break; }
					if (!ctx && (mt = rxCtx.exec(rowText))) {
						ctx = mt[1];
						ctxRow = row;
						if (def != null) break;
					}
				}
				pos.def = def;
				pos.ctx = ctx;
				pos.row = ctxRow != null ? ctxRow : row;
			}
			function reindex(file, ctx) {
				var doc = file.codeEditor.session.doc;
				var n = doc.getLength();
				var def = null, mt, nav;
				for (var i = 0; i < n; i++) {
					var line = doc.getLine(i);
					if (mt = rxDef.exec(line)) {
						def = mt[2];
						var txt = def;
						if (def != "properties") {
							var tail = mt[3].trim();
							if (tail) txt += " ➜ " + tail; // narrow space, arrow, narrow space
						}
						nav = { def: def,ctxAfter:true,showAtTop:showAtTop };
						if (mt[1]) nav.outlineViewData = "gml_" + def;
						ctx.flush(txt, txt, nav);
						continue;
					}
					else if (mt = rxPush.exec(line)) ctx.push(mt[2], mt[2], {def:def,ctx:mt[1],ctxAfter:true,showAtTop:showAtTop});
					else if (mt = rxPop.exec(line)) ctx.pop();
					else if (mt = rxMark.exec(line)) ctx.mark(mt[2], mt[2], {def:def,ctx:mt[1],ctxAfter:true,showAtTop:showAtTop});
				}
			}
			return {
				update: update,
				reindex: reindex
			}
		})(),
		"ace/mode/markdown": (function() {
			var rxDmd = /^(\s*)(#\[(.+)\](?:\(.*\))?)\s*\{\s*(?:$|[^\}])/;
			function update_dmd(file, pos) {
				var row = pos.row;
				var doc = file.codeEditor.session.doc;
				for (; row >= 0; row--) {
					var mt = rxDmd.exec(doc.getLine(row));
					if (mt) {
						pos.ctx = mt[2];
						return;
					}
				}
				pos.ctx = null;
			}
			function reindex_dmd(file, ctx) {
				var doc = file.codeEditor.session.doc;
				var n = doc.getLength();
				var stack = [], eos;
				for (var row = 0; row < n; row++) {
					var line = doc.getLine(row);
					var mt = rxDmd.exec(line);
					if (mt) {
						ctx.push(mt[3], mt[2], {ctx:mt[2],ctxAfter:true});
						if (eos) stack.push(eos);
						eos = mt[1] + "}";
					} else if (eos && line.startsWith(eos)) {
						eos = stack.pop();
						ctx.pop();
					}
				}
			}
			return {
				update: function(file, pos) {
					if (file.kind.isDocMd) update_dmd(file, pos);
				},
				reindex: function(file, ctx) {
					if (file.kind.isDocMd) reindex_dmd(file, ctx);
				}
			}
		})(),
	};
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
	function currFile() { return $gmedit["gml.file.GmlFile"].current; }
	// maybe this should be a "built-in" function instead
	function activateFile(file) {
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
	var TreeView = $gmedit["ui.treeview.TreeView"];
	var makeDir = TreeView.makeDir;
	var navPool = [];
	function makeNav_clicked(e) {
		var dir = e.target;
		if (dir.classList.contains("header")) dir = dir.parentElement;
		if (e.offsetX < dir.treeHeader.querySelector("span").offsetLeft && dir.treeItems.children.length > 0) {
			dir.classList.toggle("open");
		} else {
			if (currFile() != dir.outlineViewFile) activateFile(dir.outlineViewFile);
			if (dir.outlineViewNav) dir.outlineViewFile.navigate(dir.outlineViewNav);
		}
	}
	function makeNav(file, label, title, nav) {
		var r = navPool.pop();
		if (r) {
			r.querySelector(".header span").textContent = label;
		} else {
			r = makeDir(label);
			r.classList.add("outline-item");
			r.classList.remove("dir");
			r.treeHeader.classList.add("item");
			r.treeHeader.addEventListener("click", makeNav_clicked);
		}
		r.classList.add("open");
		r.outlineViewFile = file;
		r.outlineViewNav = nav;
		// if it's a top-level node, we let it be affected by custom CSS icon
		seta(r.treeHeader, "data-full-path", nav ? null : file.path);
		seta(r.treeHeader, "data-ident", nav ? null : file.name);
		if (!nav && file.path != null) {
			var q = TreeView.element.querySelector('.item[data-full-path="'+escapeProp(file.path)+'"]');
			if (q) {
				var th = q.getAttribute("data-thumb");
				if (th != null) r.treeHeader.setAttribute("data-thumb", th);
			}
		}
		seta(r, "outline-data", nav && nav.outlineViewData)
		seta(r, "title", title);
		seta(r, "outline-def", nav && nav.def);
		seta(r, "outline-ctx", nav && nav.ctx);
		return r;
	}
	//
	function update(file) {
		if (!file.codeEditor) return;
		var session = file.codeEditor.session;
		var conf = modeMap[session.$modeId];
		if (!conf) return;
		var pos = {
			row: session.selection.lead.row,
			def: null,
			ctx: null,
		}
		conf.update(file, pos);
		//
		var currDir = treeview.querySelector(".outline-current-file");
		if (!currDir) return;
		var currItem = currDir.querySelector(".outline-current-item");
		// if cursor is after a mark/subregion, try to highlight that,
		// or, if it's not on the sidebar yet, the nearest subregion (upwards from there)
		var nextItem;
		if (pos.ctx) {
			var prefix = pos.def ? '.outline-item[outline-def="'+escapeProp(pos.def)+'"] ' : '';
			nextItem = currDir.querySelector(prefix+'.outline-item[outline-ctx="'+escapeProp(pos.ctx)+'"]');
			while (!nextItem) {
				pos.row -= 1;
				conf.update(file, pos);
				if (pos.ctx == null) break;
				nextItem = currDir.querySelector(prefix+'.outline-item[outline-ctx="'+escapeProp(pos.ctx)+'"]');
			}
		} else if (pos.def != null) {
			nextItem = currDir.querySelector('.outline-item[outline-def="'+escapeProp(pos.def)+'"]');
		} else nextItem = null;
		//
		if (currItem != nextItem) {
			if (currItem) currItem.classList.remove("outline-current-item");
			if (nextItem) nextItem.classList.add("outline-current-item");
		}
	}
	function reindex(file) {
		var ov = file.outlineView;
		if (!file.codeEditor) return;
		// memorize which 
		var closed = ov.treeItems.querySelectorAll(".outline-item:not(.open)");
		var reclose = [];
		for (var i = 0; i < closed.length; i++) {
			var q = closed[i];
			var def = q.getAttribute("outline-def");
			var ctx = q.getAttribute("outline-ctx");
			var query = def ? '.outline-item[outline-def="'+escapeProp(def)+'"]' : "";
			if (ctx) query += (query != "" ? " " : "") + '.outline-item[outline-ctx="'+escapeProp(ctx) + '"]';
			reclose.push(query);
		}
		// pool up the existing items (should we bother, really?):
		var old = ov.treeItems.querySelectorAll(".outline-item");
		for (var i = 0; i < old.length; i++) {
			var q = old[i];
			q.outlineViewFile = null;
			q.outlineViewNav = null;
			q.treeHeader.removeAttribute("outline-data");
			q.treeHeader.removeAttribute("data-thumb");
			q.treeItems.innerHTML = "";
			navPool.push(q);
		}
		ov.treeItems.innerHTML = "";
		//
		var conf = modeMap[file.codeEditor.session.$modeId];
		if (!conf) return;
		var stack = [];
		var curr = ov;
		function finishDir(q) {
			setc(q, "outline-dir", q.treeItems.children.length > 0);
		}
		function flushStack() {
			while (stack.length > 0) finishDir(stack.pop());
			finishDir(curr);
		}
		var ctx = {
			flush: function(label, title, nav) {
				flushStack();
				var q = makeNav(file, label, title, nav);
				ov.treeItems.appendChild(q);
				return (curr = q);
			},
			push: function(label, title, nav) {
				var q = makeNav(file, label, title, nav);
				curr.treeItems.appendChild(q);
				stack.push(curr);
				return (curr = q);
			},
			pop: function() {
				finishDir(curr);
				return (curr = stack.pop() || ov);
			},
			mark: function(label, title, nav) {
				var q = makeNav(file, label, title, nav);
				finishDir(q);
				curr.treeItems.appendChild(q);
				return q;
			},
		};
		conf.reindex(file, ctx);
		flushStack();
		finishDir(ov);
		// re-collapse:
		for (var i = 0; i < reclose.length; i++) {
			var q = ov.treeItems.querySelector(reclose[i]);
			if (q) q.classList.remove("open");
		}
	}
	//
	function createFor(file) {
		var dir = makeNav(file, file.name, file.path, null);
		var item = TreeView.find(true, {path: file.path });
		if (item) TreeView.ensureThumb(item);
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
		update(e.file);
	}
	function onTabsReorder(e) {
		syncAll(e.target.tabEls);
	}
	// update current subitem on editor navigation
	var onUpdate_scheduled = false;
	function onUpdate() {
		onUpdate_scheduled = false;
		update(currFile());
	}
	function onUpdate_schedule() {
		if (onUpdate_scheduled) return;
		onUpdate_scheduled = true;
		setTimeout(onUpdate, 120);
	}
	//
	var visible = false;
	function toggle() {
		visible = !visible;
		function sete(obj, event, listener, on) {
			if (on) {
				obj.on(event, listener);
			} else obj.off(event, listener);
		}
		sete(GMEdit, "activeFileChange", onFileChange, visible);
		sete(GMEdit, "fileClose", onFileClose, visible);
		sete(GMEdit, "fileSave", onFileSave, visible);
		sete(GMEdit, "fileReload", onFileSave, visible);
		sete(GMEdit, "tabsReorder", onTabsReorder, visible);
		sete(aceEditor, "changeStatus", onUpdate_schedule, visible);
		sete(aceEditor, "changeSelection", onUpdate_schedule, visible);
		sete(aceEditor, "keyboardActivity", onUpdate_schedule, visible);
		if (visible) {
			if (!popout) {
				GMEdit.sidebar.add("Outline View", outer);
				GMEdit.sidebar.set("Outline View");
			} else document.body.insertBefore(outer, document.querySelector("#preferences-window"));
			//
			if (!currOnly) {
				syncAll();
				changeTo_post(currFile());
				onUpdate_schedule();
			} else changeTo(currFile());
		} else {
			if (!popout) {
				GMEdit.sidebar.remove("Outline View", outer);
			} else outer.parentElement.removeChild(outer);
		}
	}
	function init() {
		AceCommands.add({
			name: "toggleOutlineView",
			//bindKey: "Ctrl-Shift-O", // if you'd like
			exec: function(editor) {
				toggle();
				localStorage.setItem("outline-view-hide", !visible);
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
		},
		_modeMap: modeMap
	});
})();
