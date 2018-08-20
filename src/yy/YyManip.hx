package yy;
import electron.Dialog;
import gml.Project;
import haxe.ds.Map;
import haxe.io.Path;
import js.RegExp;
import js.html.Element;
import tools.NativeString;
import ui.treeview.TreeView;
import ui.treeview.TreeViewItemMenus;

/**
 * ...
 * @author YellowAfterlife
 */
class YyManip {
	static function resolve(q:TreeViewItemBase) {
		var pj = Project.current;
		var py:YyProject = pj.readJsonFileSync(pj.name);
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
		d.pj.reload();
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
}
