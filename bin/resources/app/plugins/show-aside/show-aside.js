/**
 * This plugin is pretty much just a demo
 * of how to instantiate extra Ace instances.
 */
(function() {
	var MenuItem = Electron_MenuItem;
	//
	var ready = false;
	var sizer, splitter, container, editor, session, mainCont;
	//
	var gmlFile = null;
	function forceUpdate() {
		var e = new CustomEvent("resize");
		e.initEvent("resize");
		window.dispatchEvent(e);
	}
	function hide() {
		if (gmlFile == null) return;
		GMEdit.off("fileClose", onFileClose);
		GMEdit.off("fileSave", onFileSave);
		mainCont.removeChild(sizer);
		mainCont.removeChild(container);
		gmlFile = null;
		forceUpdate();
		setTimeout(() => aceEditor.focus());
	}
	function show(file) {
		if (!file.codeEditor) return;
		if (gmlFile == file) return;
		if (gmlFile == null) {
			GMEdit.on("fileClose", onFileClose);
			GMEdit.on("fileSave", onFileSave);
			if (ready) {
				mainCont.appendChild(sizer);
				mainCont.appendChild(container);
			} else prepare();
			forceUpdate();
		}
		gmlFile = file;
		//
		session = GMEdit.aceTools.cloneSession(file.codeEditor.session);
		editor.setSession(session);
	}
	function onFileSave(e) {
		if (e.file == gmlFile) {
			session.bgTokenizer.start(0);
		}
	}
	function onFileClose(e) {
		if (e.file == gmlFile) hide();
	}
	//
	function prepare() {
		ready = true;
		container = document.createElement("div");
		container.classList.add("ace_container");
		//
		sizer = document.createElement("div");
		var editor_id = "aside_editor";
		sizer.setAttribute("splitter-element", "#"+editor_id);
		sizer.setAttribute("splitter-lskey", "aside_width");
		sizer.setAttribute("splitter-default-width", "400");
		sizer.classList.add("splitter-td");
		//
		var nextCont = document.createElement("div");
		nextCont.classList.add("ace_container");
		// .ace_container[editor] -> .ace_container[.ace_container[editor], splitter, .ace_container[aside_editor]]:
		mainCont = aceEditor.container.parentElement;
		var mainChildren = [];
		for (var i = 0; i < mainCont.children.length; i++) mainChildren.push(mainCont.children[i]);
		for (var i = 0; i < mainChildren.length; i++) {
			var ch = mainChildren[i];
			mainCont.removeChild(ch);
			nextCont.appendChild(ch);
		}
		mainCont.style.setProperty("flex-direction", "row");
		mainCont.appendChild(nextCont);
		mainCont.appendChild(sizer);
		mainCont.appendChild(container);
		//
		var textarea = document.createElement("textarea");
		container.appendChild(textarea);
		editor = GMEdit.aceTools.createEditor(textarea);
		//
		container.id = editor_id;
		splitter = new GMEdit_Splitter(sizer);
		// add a "Hide aside" menu item to our side view's context menu:
		var sideMenu = editor.contextMenu.menu;
		var insertAt = 0;
		while (insertAt < sideMenu.items.length) {
			if (sideMenu.items[insertAt++].aceCommand == "selectall") break;
		}
		sideMenu.insert(insertAt, new MenuItem({type:"separator"}));
		sideMenu.insert(insertAt + 1, new MenuItem({
			label: "Hide aside",
			click: function() {
				hide();
			}
		}));
		//
		editor.commands.addCommand({
			name: "saveFile",
			bindKey: {win: "Ctrl-S", mac: "Command-S"},
			exec: function(e) {
				let file = e.session.gmlFile;
				if (file && file.save()) {
					setTimeout(() => {
						if (file.codeEditor.session.getUndoManager().isClean()) {
							e.session.getUndoManager().markClean();
						}
					});
				}
			}
		});
	}
	//
	function init() {
		// add a separator and a "Show aside" menu item after "Select All" in context menu:
		var mainMenu = aceEditor.contextMenu.menu;
		var insertAt = 0;
		while (insertAt < mainMenu.items.length) {
			if (mainMenu.items[insertAt++].aceCommand == "selectall") break;
		}
		mainMenu.insert(insertAt, new MenuItem({type:"separator", id:"show-aside-sep"}));
		mainMenu.insert(insertAt + 1, new MenuItem({
			label: "Show aside",
			id: "show-aside",
			icon: __dirname + "/icons/silk/application_split_vertical.png",
			click: function() {
				show(aceEditor.session.gmlFile);
			}
		}));
	}
	//
	GMEdit.register("show-aside", {
		init: init,
		cleanup: function() {
			hide();
		},
	});
})();
