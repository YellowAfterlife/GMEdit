package yy;
import ace.extern.AceAutoCompleteItem;
import electron.Dialog;
import gml.GmlAPI;
import gml.Project;
import haxe.ds.Map;
import haxe.io.Path;
import js.RegExp;
import js.html.Element;
import tools.NativeString;
import ui.treeview.TreeView;
import ui.treeview.TreeViewItemMenus;
import yy.YyProjectResource;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyManip {
	static function resolve(q:TreeViewItemBase, ?py:YyProject) {
		var pj = Project.current;
		if (py == null) py = pj.readJsonFileSync(pj.name);
		var vp = "views/" + q.tvDir.getAttribute(TreeView.attrYYID) + ".yy";
		var vy:YyView = pj.readJsonFileSync(vp);
		var ri:YyGUID = cast q.tvRef.getAttribute(TreeView.attrYYID);
		q.pj = pj;
		return {
			pj: pj,
			py: py,
			vp: vp,
			vy: vy,
			ri: ri,
		}
	}
	public static function add(q:TreeViewItemCreate) {
		var d = resolve(q);
		if (d == null) return false;
		var pj:Project = d.pj;
		var py:YyProject = d.py;
		var kind = q.single;
		//
		var nix = YyGUID.createNum(2, d.py);
		var ni = nix[0];
		//
		var nType = switch (kind) {
			default: "GM" + NativeString.capitalize(q.single);
		};
		//
		var nBase:String, nPath:String, nDir:String;
		if (q.mkdir) {
			nBase = "views\\" + ni;
			nPath = nBase + ".yy";
			nDir = "views";
		} else {
			//
			var nTop = switch (kind) {
				default: q.plural;
			};
			pj.mkdirSync(nTop);
			//
			nDir = switch (kind) {
				default: nTop + "\\" + q.name;
			}
			pj.mkdirSync(nDir);
			//
			nBase = switch (kind) {
				default: nDir + "\\" + q.name;
			};
			nPath = switch (kind) {
				default: nBase + ".yy";
			};
			//
			q.npath = switch (kind) {
				case "script": nBase + ".gml";
				default: nPath;
			};
		}
		//
		var nJson:Dynamic;
		if (q.mkdir) {
			var nView:YyView = {
				id: ni,
				modelName: "GMFolder",
				mvc: "1.1",
				name: ni,
				children: [],
				filterType: nType,
				folderName: q.name,
				isDefaultView: false,
				localisedFolderName: "",
			};
			nType = "GMFolder";
			nJson = nView;
		} else switch (kind) {
			case "script": {
				var nyScr:YyScript = {
					id: ni,
					modelName: "GMScript",
					mvc: "1.0",
					name: q.name,
					IsCompatibility: false,
					IsDnD: false,
				};
				pj.writeTextFileSync(nBase + ".gml", "");
				nJson = nyScr;
			};
			default: {
				Dialog.showAlert("Can't create type " + q.single + "!");
				return false;
			}
		};
		//
		py.resources.push({
			Key: ni,
			Value: {
				id: nix[1],
				resourcePath: nPath,
				resourceType: nType,
			}
		});
		//
		var ord = q.order;
		switch (ord) {
			case 1, -1: {
				var i = d.vy.children.indexOf(d.ri);
				if (i >= 0) {
					d.vy.children.insert(ord > 0 ? i + 1 : i, ni);
				} else {
					if (ord < 0) {
						d.vy.children.unshift(ni);
					} else d.vy.children.push(ni);
				}
			};
			default: {
				d.vy.children.push(ni);
			};
		}
		pj.writeTextFileSync(d.vp, NativeString.yyJson(d.vy));
		//
		pj.writeTextFileSync(nPath, NativeString.yyJson(nJson));
		pj.writeTextFileSync(pj.name, NativeString.yyJson(py));
		var ntv:Element = TreeViewItemMenus.createImplTV(q);
		ntv.setAttribute(TreeView.attrYYID, ni);
		if (q.mkdir) {
			//
		} else if (kind == "script") {
			GmlAPI.gmlComp.push(new AceAutoCompleteItem(q.name, "script"));
			GmlAPI.gmlKind.set(q.name, "script");
			GmlAPI.gmlLookup.set(q.name, { path: q.npath, row: 0 });
			GmlAPI.gmlLookupText += q.name + "\n";
			parsers.GmlSeeker.runSync(pj.fullPath(q.npath), "", q.name, Normal);
			gml.file.GmlFile.open(q.name, pj.fullPath(q.npath));
		} else d.pj.reload();
		//
		return true;
	}
	public static function remove(q:TreeViewItemBase) {
		var d = resolve(q);
		if (d == null) return false;
		var pj = d.pj;
		//
		var name = q.tvRef.getAttribute(TreeView.attrIdent);
		var path = switch (q.single) {
			default: q.plural + '\\$name\\$name.yy';
		};
		var res = d.py.resources;
		//
		function rmrec(id:YyGUID) {
			// remove item, find file+path:
			var path = null, type = null;
			for (i in 0 ... res.length) {
				var pair = res[i];
				if (pair.Key == id) {
					res.splice(i, 1);
					path = pair.Value.resourcePath;
					type = pair.Value.resourceType;
					break;
				}
			}
			if (path == null) return;
			// clean up the files:
			switch (type) {
				case "GMFolder": {
					try {
						var vi:YyView = pj.readJsonFileSync(path);
						for (idc in vi.children) rmrec(idc);
						pj.unlinkSync(path);
					} catch (_:Dynamic) {
						Main.console.log(_);
					}
				};
				case "GMScript": {
					pj.unlinkSync(path);
					pj.unlinkSync(Path.withoutExtension(path) + '.gml');
					pj.rmdirSync(Path.directory(path));
				};
				default: {
					Dialog.showAlert('No idea what to clean up for type=$type, sorry');
				};
			}
		}
		rmrec(d.ri);
		pj.writeTextFileSync(pj.name, NativeString.yyJson(d.py));
		//
		if (d.vy.children.remove(d.ri)) {
			pj.writeTextFileSync(d.vp, NativeString.yyJson(d.vy));
		}
		//
		pj.reload();
		return true;
	}
	public static function rename(q:TreeViewItemRename) {
		var d = resolve(q);
		if (d == null) return false;
		var pair:YyProjectResourceValue = null;
		for (pair1 in d.py.resources) {
			if (pair1.Key == d.ri) {
				pair = pair1.Value;
				break;
			}
		}
		if (pair == null) return false;
		var pj = d.pj;
		switch (pair.resourceType) {
			case "GMFolder": {
				var vj:YyView = pj.readJsonFileSync(pair.resourcePath);
				vj.folderName = q.name;
				pj.writeJsonFileSync(pair.resourcePath, vj);
			};
			case "GMScript": {
				var path = pair.resourcePath;
				var dir = Path.directory(path);
				var ndir = Path.join([Path.directory(dir), q.name]);
				var rel = Path.withoutDirectory(path);
				pj.renameSync(dir, ndir);
				var path1 = Path.join([ndir, rel]);
				var npath1 = Path.join([ndir, q.name + ".yy"]);
				pair.resourcePath = npath1;
				pj.renameSync(path1, npath1);
				var scr:YyScript = pj.readJsonFileSync(npath1);
				scr.name = q.name;
				pj.writeJsonFileSync(npath1, scr);
				var path2 = Path.withoutExtension(path1) + ".gml";
				pj.renameSync(path2, Path.join([ndir, q.name + ".gml"]));
			};
			default: {
				Dialog.showAlert('No idea how to rename type=${pair.resourceType}, sorry');
				return false;
			};
		}
		TreeViewItemMenus.renameImpl_1(q);
		pj.writeJsonFileSync(pj.name, d.py);
		pj.reload();
		return true;
	}
	public static function move(q:TreeViewItemMove) {
		var d = resolve(q);
		if (d == null) return false;
		var pj = d.pj;
		var vy = d.vy;
		var sp = "views/" + q.srcDir.getAttribute(TreeView.attrYYID) + ".yy";
		var sy = d.vp != sp ? pj.readJsonFileSync(sp) : vy;
		var si = (cast q.srcRef.getAttribute(TreeView.attrYYID):YyGUID);
		//
		sy.children.remove(si);
		switch (q.order) {
			case 1: {
				var i = vy.children.indexOf(d.ri);
				if (i >= 0) vy.children.insert(i + 1, si); else vy.children.push(si);
			};
			case -1: {
				var i = vy.children.indexOf(d.ri);
				if (i >= 0) vy.children.insert(i, si); else vy.children.unshift(si);
			};
			default: vy.children.push(si);
		}
		//
		pj.writeTextFileSync(d.vp, NativeString.yyJson(vy));
		if (vy != sy) pj.writeTextFileSync(sp, NativeString.yyJson(sy));
		//
		moveTV(q);
		//
		return true;
	}
	public static function moveTV(q:TreeViewItemMove) {
		q.srcRef.parentElement.removeChild(q.srcRef);
		switch (q.order) {
			case 1: q.tvRef.insertAfterSelf(q.srcRef);
			case -1: q.tvRef.insertBeforeSelf(q.srcRef);
			default: q.tvDir.treeItems.appendChild(q.srcRef);
		}
	}
}
