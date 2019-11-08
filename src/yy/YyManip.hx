package yy;
import ace.extern.AceAutoCompleteItem;
import electron.Dialog;
import file.FileKind;
import file.kind.gml.KGmlScript;
import file.kind.yy.*;
import gml.GmlAPI;
import gml.Project;
import haxe.ds.Map;
import haxe.io.Path;
import js.lib.RegExp;
import js.html.Element;
import tools.NativeString;
import ui.treeview.TreeView;
import ui.treeview.TreeViewItemMenus;
import yy.YyProjectResource;
import yy.*;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class YyManip {
	static function resolve(q:TreeViewItemBase) {
		var pj = Project.current;
		var py = q.py;
		if (py == null) py = pj.readYyFileSync(pj.name);
		var vp = "views/" + q.tvDir.getAttribute(TreeView.attrYYID) + ".yy";
		var vy:YyView = pj.readYyFileSync(vp);
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
	public static function add(args:TreeViewItemCreate) {
		var d = resolve(args);
		if (d == null) return false;
		var pj:Project = d.pj;
		var py:YyProject = d.py;
		var kind = args.single;
		//
		var nix = YyGUID.createNum(2, d.py);
		var ni = nix[0];
		//
		var nType = switch (kind) {
			default: "GM" + NativeString.capitalize(args.single);
		};
		//
		var nBase:String, nPath:String, nDir:String;
		if (args.mkdir) {
			nBase = "views\\" + ni;
			nPath = nBase + ".yy";
			nDir = "views";
		} else {
			//
			var nTop = switch (kind) {
				default: args.plural;
			};
			pj.mkdirSync(nTop);
			//
			nDir = switch (kind) {
				default: nTop + "\\" + args.name;
			}
			pj.mkdirSync(nDir);
			//
			nBase = switch (kind) {
				default: nDir + "\\" + args.name;
			};
			nPath = switch (kind) {
				default: nBase + ".yy";
			};
			//
			args.npath = switch (kind) {
				case "script": nBase + ".gml";
				default: nPath;
			};
		}
		//
		var nJson:Dynamic;
		args.outGUID = ni;
		if (args.mkdir) {
			var nView:YyView = {
				id: ni,
				modelName: "GMFolder",
				mvc: "1.1",
				name: ni,
				children: [],
				filterType: nType,
				folderName: args.name,
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
					name: args.name,
					IsCompatibility: false,
					IsDnD: false,
				};
				pj.writeTextFileSync(nBase + ".gml", "");
				nJson = nyScr;
			};
			case "object": {
				var nyObj:YyObject = {
					id: ni,
					modelName: "GMObject",
					mvc: "1.0",
					name: args.name,
					eventList: [],
					maskSpriteId: YyGUID.zero,
					overriddenProperties: null,
					parentObjectId: YyGUID.zero,
					persistent: false,
					physicsAngularDamping: 0.1,
					physicsDensity: 0.5,
					physicsFriction: 0.2,
					physicsGroup: 0,
					physicsKinematic: false,
					physicsLinearDamping: 0.1,
					physicsObject: false,
					physicsRestitution: 0.1,
					physicsSensor: false,
					physicsShape: 1,
					physicsShapePoints: null,
					physicsStartAwake: true,
					properties: [],
					solid: false,
					spriteId: YyGUID.zero,
					visible: true
				};
				nJson = nyObj;
			};
			case "shader": {
				var nyShd:YyShader = {
					id: ni,
					modelName: "GMShader",
					mvc: "1.0",
					name: args.name,
					type: 1,
				};
				pj.writeTextFileSync(nBase + ".vsh", [
					'attribute vec3 in_Position;                  // (x,y,z)',
					'//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.',
					'attribute vec4 in_Colour;                    // (r,g,b,a)',
					'attribute vec2 in_TextureCoord;              // (u,v)',
					'',
					'varying vec2 v_vTexcoord;',
					'varying vec4 v_vColour;',
					'',
					'void main()',
					'{',
					'    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);',
					'    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;',
					'    ',
					'    v_vColour = in_Colour;',
					'    v_vTexcoord = in_TextureCoord;',
					'}',
				].join("\r\n"));
				pj.writeTextFileSync(nBase + ".fsh", [
					'varying vec2 v_vTexcoord;',
					'varying vec4 v_vColour;',
					'',
					'void main()',
					'{',
					'    gl_FragColor = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );',
					'}',
				].join("\r\n"));
				nJson = nyShd;
			};
			default: {
				Dialog.showAlert("No idea how to create type=`" + args.single + "`, sorry");
				return false;
			}
		};
		//
		{
			var res:YyProjectResource = {
				Key: ni,
				Value: {
					id: nix[1],
					resourcePath: StringTools.replace(nPath, "/", "\\"),
					resourceType: nType,
				}
			};
			//
			var resources = py.resources;
			var i = 0;
			while (i < resources.length) {
				if (ni.toString() < resources[i].Key.toString()) break;
				i++;
			}
			py.resources.insert(i, res);
		};
		//
		var ord = args.order;
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
			case -2: { // before the last child (fewer conflicts due to lack of trailing comma)
				var i = d.vy.children.length;
				if (i > 0) {
					d.vy.children.insert(i - 1, ni);
				} else d.vy.children.push(ni);
			};
			default: {
				d.vy.children.push(ni);
			};
		}
		pj.writeTextFileSync(d.vp, NativeString.yyJson(d.vy));
		//
		var nJsonStr = NativeString.yyJson(nJson);
		pj.writeTextFileSync(nPath, nJsonStr);
		if (args.py == null) {
			pj.writeTextFileSync(pj.name, NativeString.yyJson(py));
		}
		var ntv:Element = TreeViewItemMenus.createImplTV(args);
		ntv.setAttribute(TreeView.attrYYID, ni);
		if (args.mkdir) {
			//
		} else switch (kind) {
			case "script", "object", "shader": {
				GmlAPI.gmlComp.push(new AceAutoCompleteItem(args.name, kind));
				GmlAPI.gmlKind.set(args.name, "asset." + kind);
				GmlAPI.gmlLookup.set(args.name, { path: args.npath, row: 0 });
				GmlAPI.gmlLookupText += args.name + "\n";
				var fk:FileKind = switch (kind) {
					case "object": file.kind.yy.KYyEvents.inst;
					case "shader": null;
					default: KGmlScript.inst;
				}
				var src = kind == "script" ? "" : nJsonStr;
				if (fk != null) parsers.GmlSeeker.runSync(pj.fullPath(args.npath), src, args.name, fk);
				if (args.openFile != false) {
					gml.file.GmlFile.open(args.name, pj.fullPath(args.npath));
				}
			};
			default: d.pj.reload();
		}
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
		// remove a directory and all items (we don't need to worry about perms)
		function removeDirRec(path:String) {
			if (!pj.existsSync(path)) return;
			for (pair in pj.readdirSync(path)) {
				if (pair.isDirectory) {
					removeDirRec(pair.relPath);
				} else {
					pj.unlinkSync(pair.relPath);
				}
			}
			pj.rmdirSync(path);
		}
		function removeItemRec(id:YyGUID) {
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
			if (path == null) return true;
			// clean up the files:
			switch (type) {
				case "GMFolder": {
					try {
						var vi:YyView = pj.readYyFileSync(path);
						for (idc in vi.children) removeItemRec(idc);
						try {
							pj.unlinkSync(path);
						} catch (_:Dynamic) {}
					} catch (x:Dynamic) {
						Main.console.log(x);
					}
				};
				case "GMScript", "GMObject", "GMSprite", "GMShader": {
					removeDirRec(Path.directory(path));
				};
				default: {
					Dialog.showAlert('No idea how to remove type `$type`, sorry');
					return false;
				};
			}
			return true;
		}
		if (!removeItemRec(d.ri)) return false;
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
				var vj:YyView = pj.readYyFileSync(pair.resourcePath);
				vj.folderName = q.name;
				pj.writeYyFileSync(pair.resourcePath, vj);
			};
			case "GMScript", "GMObject", "GMShader", "GMSprite": {
				var path = pair.resourcePath;
				var dir = Path.directory(path);
				var ndir = Path.join([Path.directory(dir), q.name]);
				var rel = Path.withoutDirectory(path);
				pj.renameSync(dir, ndir);
				//
				var curr_yy = Path.join([ndir, rel]);
				var next_yy = Path.join([ndir, q.name + ".yy"]);
				pair.resourcePath = next_yy;
				pj.renameSync(curr_yy, next_yy);
				var next_res:YyResource = pj.readYyFileSync(next_yy);
				next_res.name = q.name;
				pj.writeYyFileSync(next_yy, next_res);
				//
				var samename:Array<String> = switch (pair.resourceType) {
					case "GMScript": ["gml"];
					case "GMShader": ["fsh", "vsh"];
					default: null;
				}
				if (samename != null)
				for (ext in samename) {
					var sfx = "." + ext;
					var curr_gml = Path.withoutExtension(curr_yy) + sfx;
					var next_gml = Path.join([ndir, q.name + sfx]);
					pj.renameSync(curr_gml, next_gml);
				}
			};
			default: {
				Dialog.showAlert('No idea how to rename type=${pair.resourceType}, sorry');
				return false;
			};
		}
		TreeViewItemMenus.renameImpl_1(q);
		pj.writeYyFileSync(pj.name, d.py);
		pj.reload();
		return true;
	}
	public static function move(q:TreeViewItemMove) {
		var d = resolve(q);
		if (d == null) return false;
		var pj = d.pj;
		var vy = d.vy;
		var sp = "views/" + q.srcDir.getAttribute(TreeView.attrYYID) + ".yy";
		var sy = d.vp != sp ? pj.readYyFileSync(sp) : vy;
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
