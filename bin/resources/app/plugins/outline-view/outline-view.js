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
	var Preferences = $gmedit["ui.Preferences"];
	var FileWrap = $gmedit["electron.FileWrap"];
	var popout = false; // show a popout instead of a sidebar
	var displayMode = 1;
	var currOnly = false; // original idea (only show the current file)
	var noIndex = false;
	function setDisplayMode(m) {
		displayMode = m;
		currOnly = (m == 0);
		noIndex = (m == 3);
	}
	var showAtTop = true;
	var showFuncArgs = false;
	var tailSep = " ➜ "; // narrow space, arrow, narrow space
	//
	var Menuitem = Electron_MenuItem;
	var ctxMenu = new Electron_Menu();
	var ctxItem = null;
	ctxMenu.append(new Menuitem({
		id: "open",
		label: "Open",
		click: function() {
			ctxItem.querySelector(".header").click();
		}
	}));
	ctxMenu.append(new Menuitem({
		id: "copy-name",
		label: "Copy &name",
		click: function() {
			var text = ctxItem.getAttribute("outline-def");
			navigator.clipboard.writeText(text);
		}
	}));
	ctxMenu.append(new Menuitem({
		id: "copy-text",
		label: "Copy &text",
		click: function() {
			var text = ctxItem.querySelector(".header").innerText;
			navigator.clipboard.writeText(text);
		}
	}));
	//
	var escapeProp = $gmedit["tools.NativeString"].escapeProp;
	var modeMap = {
		"ace/mode/gml": (function() {
			var rxDef = /^((#event)|#define|#moment|#section|#roomcc)\b\s*(\w+(?::\w+)?)(.*)$/;
			var rxFunc = new RegExp("^function"
				+ "\\s+(\\w+)" // name
				+ "\\s*(\\(.*?\\))" // args
				+ "(?:.*?\\/\\/(.*))?" // post-comment
			);
			var rxSubFunc = new RegExp("^\\s+"
				+ "("
					+ "(?:static\\s+)?(\\w+)\\s*=\\s*function"
					+ "|"
					+ "function\\s+(\\w+)"
				+ ")"
				+ "\\s*(\\(.*?\\))" // args
				+ "(?:.*?\\/\\/(.*))?" // post-comment
			);
			var rxShorthandFunc = new RegExp("^\\s*"
				+ "(?:static\\b\\s*)?"
				+ "(\\w+)"
				+ "\\s*=\\s*"
				+ "(\\(.*?\\))" + "\\s*=>\\s*" + "\\{"
			)
			var rxPush = /^\s*((?:#region|\/\/#region)\b\s*(.*))$/;
			var rxPop = /^\s*(?:#endregion|\/\/#endregion)\b/;
			var rxMark = /^\s*((?:\/\/#mark|#section)\b\s*(.*))$/;
			var rxCtx = /^\s*((?:#region|\/\/#region|\/\/#mark)\b.*)$/
			function update_gml(file, pos) {
				var def = pos.def, row = pos.row;
				var ctx = null, ctxRow = null;
				var doc = file.codeEditor.session.doc;
				for (; row >= 0; row--) {
					var rowText = doc.getLine(row), mt;
					if (mt = rxDef.exec(rowText)) {
						def = mt[3];
						break;
					}
					if (mt = rxFunc.exec(rowText)) {
						def = mt[1];
						break;
					}
					if (ctx) continue;
					if (mt = rxCtx.exec(rowText)) {
						ctx = mt[1];
						ctxRow = row;
						if (def != null) break;
					} else if (mt = rxSubFunc.exec(rowText)) {
						ctx = (mt[2] || mt[3]);
						ctxRow = row;
						if (def != null) break;
					} else if (mt = rxShorthandFunc.exec(rowText)) {
						ctx = mt[1];
						ctxRow = row;
						if (def != null) break;
					}
				}
				pos.def = def;
				pos.ctx = ctx;
				pos.row = ctxRow != null ? ctxRow : row;
			}
			function reindex_gml(file, ctx) {
				var doc = file.codeEditor.session.doc;
				var n = doc.getLength();
				var def = null;
				for (var i = 0; i < n; i++) {
					var line = doc.getLine(i), mt;
					if (mt = rxDef.exec(line)) { // #define, #event, etc.
						def = mt[3];
						var label = def, title = mt[1] + " " + def;
						
						var tail = (mt[4] || "").trim();
						if (tail && def != "properties") {
							label += tailSep + tail;
							title += "\n" + tail;
						}
						
						var nav = { def: def, ctxAfter: true, showAtTop: showAtTop };
						
						// if this is an event, we set an attribute so that we can have different icons for them
						if (mt[1]) nav.outlineViewData = "gml_" + def;
						
						ctx.flush(label, title, nav);
					} else if (mt = rxFunc.exec(line)) { // 2.3 top-level functions
						def = mt[1];
						var label = def, title = "function " + def;
						
						if (showFuncArgs) label += mt[2];
						title += mt[2];
						
						var tail = (mt[3] || "").trim();
						if (tail) {
							label += tailSep + tail;
							title += "\n" + tail;
						}
						
						var nav = { def: def, ctxAfter: true, showAtTop: showAtTop };
						ctx.flush(label, title, nav);
					} else if (mt = rxSubFunc.exec(line)) {
						var name = mt[2] || mt[3];
						var label = name, title = mt[1];
						
						if (showFuncArgs) label += mt[4];
						title += mt[4];
						
						var tail = (mt[5] || "").trim();
						if (tail) {
							label += tailSep + tail;
							title += "\n" + tail;
						}
						var rx;
						if (mt[2]) {
							rx = new RegExp("\\b" + name + "\\b\\s*=\\s*function\\b");
						} else {
							rx = new RegExp("\\bfunction\\s+" + name + "\\b");
						}
						
						var nav = {
							def: def,
							ctx: name,
							ctxRx: rx,
							ctxAfter: true,
							showAtTop: showAtTop
						};
						ctx.mark(label, title, nav);
					} else if (mt = rxShorthandFunc.exec(line)) { // shorthand
						var label = mt[1], title = mt[1];
						rx = new RegExp("\\b" + label + "\\b\\s*=\\s*\\(");

						if (showFuncArgs) label += mt[2];
						title += mt[2];
						
						var nav = { def: def, ctx: mt[1], ctxRx: rx, ctxAfter: true, showAtTop: showAtTop };
						ctx.mark(label, title, nav);
					} else if (mt = rxPush.exec(line)) {
						var nav = { def: def, ctx: mt[1], ctxAfter: true, showAtTop: showAtTop };
						ctx.push(mt[2], mt[0], nav);
					} else if (mt = rxPop.exec(line)) {
						ctx.pop();
					} else if (mt = rxMark.exec(line)) {
						var nav = { def: def, ctx: mt[1], ctxAfter: true, showAtTop: showAtTop };
						ctx.mark(mt[2], mt[0], nav);
					}
				}
			}
			return {
				update: update_gml,
				reindex: reindex_gml
			}
		})(),
		"ace/mode/markdown": (function() {
			var rxDmd = /^(\s*)(#\[(.+)\](?:\(.*\))?)\s*\{\s*(?:$|[^\}\s])/;
			//                 ##     [Title]
			var rxDmd2 = /^\s*(#+)(?:\[(.+)\]|(.+))/;
			var rxDmd2ex = /^(define\b|macro\b)/;
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
				var depth = 0;
				for (var row = 0; row < n; row++) {
					var line = doc.getLine(row);
					var mt;
					if (mt = rxDmd.exec(line)) {
						ctx.push(mt[3], mt[2], {ctx:mt[2],ctxAfter:true});
						if (eos) stack.push(eos);
						eos = mt[1] + "}";
					} else if (eos && line.startsWith(eos)) {
						eos = stack.pop();
						ctx.pop();
					} else if (mt = rxDmd2.exec(line)) {
						var name = mt[2] || mt[3];
						if (rxDmd2ex.test(name)) continue;
						var newDepth = mt[1].length;
						if (newDepth > depth) {
							ctx.push(name, mt[0], { ctx: name,ctxAfter:true});
						} else if (newDepth < depth) {
							ctx.pop();
							ctx.pop();
							ctx.push(name, mt[0], { ctx: name,ctxAfter:true});
						} else {
							ctx.pop();
							ctx.push(name, mt[0], { ctx: name,ctxAfter:true});
							//ctx.mark(name, mt[0], { ctx: name, ctxAfter: true });
						}
						depth = newDepth;
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
		"$preferences": (function() {
			function pref_getRoot(file) {
				var parent = file.editor.element;
				if (parent.children.length == 1) parent = parent.children[0];
				return parent;
			}
			function pref_update(file, pos) {
				var parent = pref_getRoot(file);
				var groups = parent.querySelectorAll("fieldset");
				var i = groups.length;
				var scroller = file.editor.element;
				var scrollTop = scroller.scrollTop + 40; // scroller.offsetHeight / 2
				while (--i >= 0) {
					var group = groups[i];
					var legend = group.querySelector("legend");
					var label = group.dataset.outlineViewLabel;
					if (group.parentElement != parent && label == null) continue;
					if (group.offsetTop <= scrollTop) {
						if (group.id) {
							pos.def = group.id;
						} else {
							if (!label) label = legend.textContent.replace(/\(.+\)$/, "");
							pos.ctx = label;
						}
						return;
					}
				}
				pos.def = pos.ctx = null;
			}
			function pref_scroll(e) {
				update(this);
			}
			function pref_reindex(file, ctx) {
				var prefRoot = pref_getRoot(file);
				var groups = prefRoot.querySelectorAll("fieldset");
				var groupChain = [];
				for (var i = 0; i < groups.length; i++) {
					var group = groups[i];
					var legend = group.querySelector("legend");
					var label = group.dataset.outlineViewLabel;
					if (group.parentElement != prefRoot && label == null) continue;
					if (!label) label = legend.textContent.replace(/\(.+\)$/, "");
					var nav = {};
					if (group.id) {
						nav.def = group.id;
					} else {
						nav.ctx = legend.textContent;
					}
					while (groupChain.length > 0) {
						var curParent = groupChain[groupChain.length - 1];
						var inCurParent = false;
						var parent = group.parentElement;
						while (parent) {
							if (parent == curParent) inCurParent = true;
							parent = parent.parentElement;
						}
						if (!inCurParent) {
							ctx.pop();
							groupChain.pop();
						} else break;
					}
					groupChain.push(group);
					ctx.push(label, label, nav);
				}
				if (!file.outlineViewScroll) {
					file.outlineViewScroll = true;
					file.editor.element.addEventListener("scroll", pref_scroll.bind(file));
					file.editor.element.addEventListener("resize", pref_scroll.bind(file));
					setTimeout(function() {
						update(file);
					}, 1);
				}
			}
			return {
				update: pref_update,
				reindex: pref_reindex
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
	
	/**
	 * Focus the given file's tab.
	 * @param {GMEdit.GmlFile} file
	 */
	function activateFile(file) {
		file.tabEl?.click();
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
	function makeNav_contextmenu(e) {
		var dir = e.target, header;
		if (dir.classList.contains("header")) {
			header = dir;
			dir = dir.parentElement;
		} else header = dir.querySelector(".header");
		ctxItem = dir;
		header.classList.add("selected");
		ctxMenu.popup({
			async: true,
			callback: function() {
				header.classList.remove("selected");
			}
		});
	}

	/**
	 * Change the label for the given navigation item.
	 * 
	 * @param {HTMLDivElement} item 
	 * @param {string} label 
	 */
	function setNavItemLabel(item, label) {
		item.treeHeader.querySelector("span.label").textContent = label;
	}

	function makeNav(file, label, title, nav) {
		var r = navPool.pop();
		if (r) {
			setNavItemLabel(r, label);
		} else {
			r = makeDir(label);
			r.classList.add("outline-item");
			r.classList.remove("dir");
			r.treeHeader.classList.add("item");
			r.treeHeader.addEventListener("click", makeNav_clicked);
			r.treeHeader.addEventListener("contextmenu", makeNav_contextmenu);
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
		seta(r.treeHeader, "title", title);
		seta(r, "outline-def", nav && nav.def);
		seta(r, "outline-ctx", nav && nav.ctx);
		return r;
	}
	//
	function getConf(file) {
		if (file.codeEditor) {
			return modeMap[file.codeEditor.session.$modeId];
		} else if (file.kind instanceof $gmedit["file.kind.misc.KPreferencesBase"]) {
			return modeMap["$preferences"];
		} else return null;
	}
	function update(file) {
		var conf = getConf(file);
		if (!conf) return;
		var pos = {
			row: null,
			def: null,
			ctx: null,
		};
		var currDir;
		if (file.codeEditor) {
			var session = file.codeEditor.session;
			var row = session.selection.lead.row;
			
			// if the cursor is inside JSDoc line immediately before a function, highlight the function instead
			var rxJSDoc = /^\s*\/\/\/\s*@.*/;
			var rows = session.getLength();
			while (row < rows && rxJSDoc.test(session.getLine(row))) row++;
			
			pos.row = row;
			conf.update(file, pos);
			//
			currDir = treeview.querySelector(".outline-current-file");
		} else {
			conf.update(file, pos);
			currDir = treeview.querySelector(".outline-current-file");
		}
		if (!currDir) return;
		var currItem = currDir.querySelector(".outline-current-item");
		// if cursor is after a mark/subregion, try to highlight that,
		// or, if it's not on the sidebar yet, the nearest subregion (upwards from there)
		var nextItem;
		if (pos.ctx) {
			var prefix = pos.def ? '.outline-item[outline-def="'+escapeProp(pos.def)+'"] ' : '';
			nextItem = currDir.querySelector(prefix+'.outline-item[outline-ctx="'+escapeProp(pos.ctx)+'"]');
			while (!nextItem && pos.row >= 0) {
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
		var conf = getConf(file);
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
		if (!noIndex) conf.reindex(file, ctx);
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
			if (displayMode == 2) {
				if (tabEl.classList.contains("chrome-tab-current")) {
					file.outlineView.classList.add("open");
				} else file.outlineView.classList.remove("open");
			}
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
				treeview.innerHTML = "";
				treeview.appendChild(nextEl);
				currEl = nextEl;
			}
		} else {
			var ov = file.outlineView;
			if (displayMode == 2) {
				for (var i = 0; i < treeview.children.length; i++) {
					var dir = treeview.children[i];
					if (!dir.classList || !dir.classList.contains("outline-dir")) continue;
					if (dir == ov) {
						dir.classList.add("open");
					} else dir.classList.remove("open");
				}
			}
			if (ov.scrollIntoViewIfNeeded) {
				ov.scrollIntoViewIfNeeded();
			} else ov.scrollIntoView();
		}
		changeTo_post(file);
	}
	function forceRefresh() {
		var tabEls = $gmedit["ui.ChromeTabs"].impl.tabEls;
		for (var i = 0; i < tabEls.length; i++) {
			var tabEl = tabEls[i];
			var file = tabEl.gmlFile;
			if (!file) continue;
			file.outlineView = null;
		}
		treeview.innerHTML = "";
		if (!currOnly) {
			syncAll();
		} else {
			changeTo(currFile());
		}
	}
	//
	function onFileChange(e) {
		changeTo(e.file);
	}
	function onFileClose(e) {
		if (!currOnly) syncAll();
	}
	function onFileSave(e) {
		reindex(e.file);
		update(e.file);
	}
	function onTabsReorder(e) {
		if (!currOnly) syncAll(e.target.tabEls);
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
	var toggleCheckbox = null;
	function toggle_sync() {
		if (!currOnly) {
			syncAll();
			changeTo_post(currFile());
			onUpdate_schedule();
		} else changeTo(currFile());
	}
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
		if (toggleCheckbox) toggleCheckbox.checked = !visible;
		if (visible) {
			if (!popout) {
				GMEdit.sidebar.add("Outline View", outer);
				GMEdit.sidebar.set("Outline View");
			} else document.body.insertBefore(outer, document.querySelector("#preferences-window"));
			//
			toggle_sync();
		} else {
			if (!popout) {
				GMEdit.sidebar.remove("Outline View", outer);
			} else outer.parentElement.removeChild(outer);
		}
	}

	/**
	 * Update a file's name and path in the outline view when it is modified.
	 * @param {{ file: GMEdit.GmlFile }} event 
	 */
	function onFileRename({ file }) {

		if ('outlineView' in file) {
			setNavItemLabel(file.outlineView, file.name);
		}

	}

	function opt(ov, name, def) {
		if (!ov) return def;
		var val = ov[name];
		return val !== undefined ? val : def;
	}

	function getDisplayMode(currOV) {
		var dm = opt(currOV, "displayMode", null);
		if (dm == null) dm = opt(currOV, "currOnly", false) ? 0 : 1;
		return dm;
	}

	var toggleOutlineViewCommand;
	var toggleOutlineViewPaletteCommand;

	var currPrefs = Preferences.current;
	var currOV = currPrefs.outlineView;
	
	function prepareOV() {
		currOV = Preferences.current.outlineView;
		if (!currOV) currOV = Preferences.current.outlineView = {};
		return currOV;
	}

	GMEdit.register("outline-view", {
		init: () => {

			toggleOutlineViewCommand = {
				name: "toggleOutlineView",
				//bindKey: "Ctrl-Shift-O", // if you'd like
				exec: function(editor) {
					toggle();
					var currPrefs = FileWrap.readConfigSync("config", Preferences.path);
					if (currPrefs) {
						currOV = currPrefs.outlineView;
						if (currOV == null) currOV = currPrefs.outlineView = {};
						currOV.hide = !visible;
						FileWrap.writeConfigSync("config", Preferences.path, currPrefs);
					}
				}
			};

			toggleOutlineViewPaletteCommand = {
				name: "Toggle outline view",
				exec: "toggleOutlineView",
				title: ""
			};

			AceCommands.add(toggleOutlineViewCommand);
			AceCommands.addToPalette(toggleOutlineViewPaletteCommand);
			
			setDisplayMode(getDisplayMode(currOV))
			showAtTop = opt(currOV, "showAtTop", true);
			showFuncArgs = opt(currOV, "showFuncArgs", true);
	
			GMEdit.on("fileRename", onFileRename);

			if (!(currOV && currOV.hide)) {
				toggle();
			}
	
		},
		cleanup: function() {

			AceCommands.remove(toggleOutlineViewCommand);
			AceCommands.removeFromPalette(toggleOutlineViewPaletteCommand);

			GMEdit.off("fileRename", onFileRename);

			if (visible) {
				toggle();
			}

		},
		buildPreferences: (out) => {
			currOV = Preferences.current.outlineView;
			var hideCtr = Preferences.addCheckbox(out, "Hide", currOV && currOV.hide, function(val) {
				toggle();
				currOV = prepareOV();
				currOV.hide = !visible;
				Preferences.save();
			});
			toggleCheckbox = hideCtr.querySelector("input");
			var displayModes = [
				"Only show the currently active document",
				"Show all documents",
				"Show all documents, auto-collapse inactive",
				"Show document titles only",
			];
			Preferences.addDropdown(out, "Display mode", displayModes[getDisplayMode(currOV)], displayModes, function(val) {
				var i = displayModes.indexOf(val);
				currOV = prepareOV();
				currOV.displayMode = i;
				setDisplayMode(i);
				Preferences.save();
				toggle_sync();
				forceRefresh();
			})
			Preferences.addCheckbox(out, "Show 2.3 function arguments", opt(currOV, "showFuncArgs", true), function(val) {
				currOV = prepareOV();
				showFuncArgs = currOV.showFuncArgs = val;
				currEl = null;
				Preferences.save();
				forceRefresh();
			});
			Preferences.addCheckbox(out, "Scroll to top upon navigation", opt(currOV, "showAtTop", true), function(val) {
				currOV = prepareOV();
				showAtTop = currOV.showAtTop = val;
				currEl = null;
				Preferences.save();
				forceRefresh();
			});
		},
		_modeMap: modeMap
	});

})();
