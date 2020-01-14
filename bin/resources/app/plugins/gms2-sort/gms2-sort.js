(function() {
	var TreeViewMenus = $gmedit["ui.treeview.TreeViewMenus"];
	function proj() {
		return $gmedit["gml.Project"].current;
	}
	function scmp(a, b) {
		return a < b ? -1 : (a > b ? 1 : 0);
	}
	function onClick() {
		var target = TreeViewMenus.target;
		var yyid = target.getAttribute("data-yyid");
		if (!yyid) return;
		var pj = proj();
		var asc = confirm("Ascending (A,B,C)?");
		var rec = confirm("Recursive?");
		var txt = "You are about to sort `" + target.getAttribute("data-rel-path") + "`";
		if (rec) txt += " and it's children";
		txt += " in " + (asc ? "a" : "de") + "scending order. This cannot be undone. Continue?";
		var sortDir = asc ? 1 : -1;
		if (!confirm(txt)) return;
		function nameof(id) {
			var pair = pj.yyResources[id];
			return pair ? pair.Value.resourceName : "";
		}
		function procDir(yyid) {
			var path = "views/" + yyid + ".yy";
			var view = pj.readJsonFileSync(path);
			view.children.sort(function(a, b) {
				return sortDir * scmp(nameof(a), nameof(b));
			});
			pj.writeJsonFileSync("views/" + yyid + ".yy", view);
			if (rec) for (var i = 0; i < view.children.length; i++) {
				var chid = view.children[i];
				var pair = pj.yyResources[chid];
				if (pair && pair.Value.resourceType == "GMFolder") procDir(chid);
			}
		}
		procDir(yyid);
		pj.reload();
	}
	GMEdit.register("gms2-sort", {
		init: function() {
			var menuItem = new Electron_MenuItem({
				label: "Sort",
				click: onClick,
			});
			$gmedit["ui.treeview.TreeView"].on("dirMenu", function(e) {
				menuItem.visible = proj().version.config.projectMode == "gms2";
			});
			//
			var menu = TreeViewMenus.dirMenu;
			var insertAt = 0;
			while (insertAt < menu.items.length) {
				var check = menu.items[insertAt++];
				if (check.type == "separator") { insertAt--; break; }
				if (check.label.includes("Combined")) break;
			}
			menu.insert(insertAt, menuItem);
			//
		}
	});
})();
