package ui.preferences;
import js.html.Element;
import tools.NativeString;
import ui.Preferences.*;
import gml.GmlVersion;
import electron.FileSystem;
import electron.FileWrap;
import plugins.*;
import Main.document;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefPlugins {
	static function makePluginItem(out:Element, p:PluginState) {
		var group = addGroup(out, "");
		var el:Element = group.querySelectorAuto("legend");
		group.classList.add("plugin-info");
		group.setAttribute("for", p.name);
		var syncLabelState:Void->Void = null;
		//
		var p_label = document.createLabelElement();
		p_label.appendChild(document.createTextNode(p.name));
		el.appendChild(p_label);
		//
		el.appendChild(document.createTextNode(" ("));
		el.append(createShellAnchor(p.dir, "open"));
		//
		var p_conf:Element = null;
		var p_reload = document.createSpanElement(); {
			p_reload.appendChild(document.createTextNode("; "));
			p_reload.appendChild(createFuncAnchor("reload", function(_) {
				p_conf.clearInner();
				p.destroy();
				PluginManager.load(p.name, function(e) {
					p = PluginManager.pluginMap[p.name];
					syncLabelState();
				});
			}));
			el.append(p_reload);
		};
		//
		el.appendChild(document.createTextNode(")"));
		//
		var p_desc = document.createDivElement();
		p_desc.classList.add("plugin-description");
		group.appendChild(p_desc);
		//
		p_conf = document.createDivElement();
		p_conf.classList.add("plugin-settings");
		p_conf.setAttribute("for", p.name);
		group.appendChild(p_conf);
		//
		syncLabelState = function syncLabelState() {
			p_label.classList.setTokenFlag("error", p.error != null);
			if (p.error != null) {
				p_label.style.pointerEvents = "";
				p_label.title = Std.string(p.error);
			} else p_label.style.pointerEvents = "none";
			p_reload.setDisplayFlag(p.data == null || p.data.cleanup != null);
			//
			var desc = p.config.description;
			if (desc != null && NativeString.trimBoth(desc) == "") desc = null;
			if (desc != null) p_desc.setInnerText(desc);
		}
		syncLabelState();
	}
	public static function build(out:Element) {
		out = addGroup(out, "Plugins");
		out.id = "pref-plugins";
		var el:Element;
		//
		addText(out, "Currently loaded plugins:");
		for (p_name in PluginManager.pluginList) {
			var p = PluginManager.pluginMap[p_name];
			makePluginItem(out, p);
		}
		//
		el = out.querySelector('legend');
		el.appendChild(document.createTextNode(" ("));
		el.append(createShellAnchor("https://github.com/GameMakerDiscord/GMEdit/wiki/Using-plugins", "wiki"));
		if (FileSystem.canSync) {
			el.appendChild(document.createTextNode("; "));
			el.append(createShellAnchor(FileWrap.userPath + "/plugins", "manage"));
		}
		el.appendChild(document.createTextNode(")"));
		//
	}
}