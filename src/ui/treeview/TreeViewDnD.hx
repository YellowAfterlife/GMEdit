package ui.treeview;
import gml.Project;
import js.lib.RegExp;
import js.html.DragEvent;
import js.html.Element;
import tools.NativeString;
import ui.treeview.TreeViewItemMenus;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class TreeViewDnD {
	static var currEl:Element = null;
	static var currOrder:Int = 0;
	static var currClass:String;
	static function update(el:Element, order:Int) {
		if (currEl == el && currOrder == order) return;
		if (currEl != null) {
			var el = currEl;
			var cl = currClass;
			Main.window.setTimeout(function() {
				el.classList.remove(cl);
			}, 50);
		}
		currEl = el;
		currOrder = order;
		currClass = switch (order) {
			case 1: "drop-after";
			case -1: "drop-before";
			default: "drop-into";
		}
		if (currEl != null) {
			currEl.classList.add(currClass);
		}
	}
	//
	static inline var dropType = "text/gmedit-rel-path";
	static inline var dropPrefix = "text/gmedit-rel-prefix";
	static inline var rsCanDrop = "^scripts[\\\\/]";
	static var rxCanDropTo = new RegExp(rsCanDrop, "i");
	static var rxCanDrag = new RegExp(rsCanDrop + ".+", "i");
	static var rxCanDrag2 = new RegExp("^[^\\\\/]+[\\\\/].", "");
	static var prefixOf_rx = new RegExp("^([^\\\\/]+)[\\\\/]", "");
	static function prefixOf(rel:String):String {
		var mt = prefixOf_rx.exec(rel);
		return mt != null ? mt[1] : "";
	}
	static function hasType(e:DragEvent, t:String):Bool {
		var dtTypes:Dynamic = e.dataTransfer.types;
		return dtTypes.indexOf
			? dtTypes.indexOf(t) >= 0
			: dtTypes.contains(t);
	}
	public static function bind(el:Element, rel:String) {
		var dir = el.classList.contains("header");
		var prefix = prefixOf(rel).toLowerCase();
		var ownType = dropType + "=" + rel.toLowerCase();
		var ownPrefix = dropPrefix + "=" + prefix;
		var v2 = Project.current.version.config.projectModeId == 2;
		var v23 = v2 && !Project.current.yyUsesGUID;
		if (v2 || rxCanDropTo.test(rel)) {
			function updateAuto(e:DragEvent) {
				var y = e.offsetY;
				var h = el.scrollHeight;
				var th = dir ? 0.25 : 0.35;
				if (!v23 && !hasType(e, ownPrefix)) {
					update(null, 0);
				} else if (y < h * th) {
					update(el, -1);
				} else if (y > h * (1 - th)) {
					update(el, 1);
				} else {
					update(dir && !hasType(e, ownType) ? el : null, 0);
				}
			}
			el.addEventListener("dragover", (e:DragEvent) -> {
				e.preventDefault();
				//untyped window.bok = e;
				updateAuto(e);
			});
			el.addEventListener("dragleave", (e:DragEvent) -> {
				update(null, 0);
			});
			function dropRel(dst:Element, rel:String, order:Int) {
				var src = TreeView.find(!NativeString.endsWith(rel, '/'), {rel:rel});
				if (src == null) return;
				if (src.classList.contains("header")) src = src.parentElement;
				// verify that we're not moving something into itself:
				var root = TreeView.element;
				var par = dst;
				while (par != null && par != root) {
					if (par == src) return;
					par = par.parentElement;
				}
				//
				var project = Project.current;
				var d = TreeViewItemMenus.getItemData(dst);
				var d2 = TreeViewItemMenus.getItemData(src);
				var args:TreeViewItemMove = {
					prefix: d.prefix,
					plural: d.plural,
					single: d.single,
					chain: d.chain,
					last: d.last,
					tvDir: cast (order != 0 ? dst.parentElement.parentElement : dst),
					tvRef: dst,
					srcChain: d2.chain,
					srcLast: d2.last,
					srcDir: cast src.parentElement.parentElement,
					srcRef: cast src,
					order: order,
					pj: project,
				};
				switch (project.version.config.projectModeId) {
					case 2: {
						if (project.yyUsesGUID) {
							yy.v22.YyManipV22.move(args);
						} else yy.YyManip.move(args);
					};
					case 1: gmx.GmxManip.move(args);
					default:
				}
			}
			el.addEventListener("drop", (e:DragEvent) -> {
				//Main.console.log(e);
				updateAuto(e);
				var dst = currEl;
				if (dst == null) return;
				if (dst.classList.contains("header")) dst = dst.parentElement;
				TreeViewItemMenus.updatePrefix(dst);
				var order = currOrder;
				Main.console.log(order);
				update(null, 0);
				if (order > 0 && dst.classList.contains(TreeView.clDir) && dst.classList.contains(TreeView.clOpen)) {
					var dstItems:Element = (cast dst:TreeViewDir).treeItems;
					if (dstItems.children.length > 0) {
						dst = dstItems.children[0];
						order = -1;
					} else order = 0;
				}
				if (order != 0 && dst.parentElement == TreeView.element) {
					return;
				}
				var rel = e.dataTransfer.getData(dropType);
				if (rel != null) {
					dropRel(dst, rel, order);
					return;
				}
			});
		}
		if ((v2?rxCanDrag2:rxCanDrag).test(rel)) {
			el.setAttribute("draggable", "true");
			el.addEventListener("dragstart", (e:DragEvent) -> {
				e.dataTransfer.setData(dropType, rel);
				e.dataTransfer.setData(ownType, "");
				e.dataTransfer.setData(dropPrefix, prefix);
				e.dataTransfer.setData(ownPrefix, "");
			});
		}
	}
}
