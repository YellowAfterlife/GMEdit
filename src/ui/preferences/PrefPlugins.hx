package ui.preferences;
import js.html.LegendElement;
import js.html.AnchorElement;
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
		var legend:LegendElement = group.querySelectorAuto("legend");
		group.classList.add("plugin-info");
		group.setAttribute("for", p.name);
		var syncState:Void->Void = null;
		//
		var p_label = document.createLabelElement();
		p_label.appendChild(document.createTextNode(p.name));
		legend.appendChild(p_label);

		final p_desc = document.createDivElement();
		p_desc.classList.add("plugin-description");
		group.appendChild(p_desc);

		final p_conf:Element = document.createDivElement();
		p_conf.classList.add("plugin-settings");
		p_conf.setAttribute("for", p.name);
		group.appendChild(p_conf);

		legend.appendChild(document.createTextNode("("));
		
		final openButton = createShellAnchor(p.dir, "open");
		legend.appendChild(openButton);

		final toggleButton = createFuncAnchor("", function(_) {

			if (!PluginManager.isEnabled(p.name)) {
				PluginManager.enable(p.name);
			} else {
				p_conf.clearInner();
				PluginManager.disable(p.name);
			}

			syncState();

		});

		final toggleButtonContainer = document.createSpanElement();
		toggleButtonContainer.appendChild(document.createTextNode("; "));
		toggleButtonContainer.appendChild(toggleButton);
		legend.appendChild(toggleButtonContainer);

		final reloadButton = createFuncAnchor("reload", function(_) {
			
			p_conf.clearInner();

			PluginManager.reload(p.name, function(_) {
				syncState();
			});

		});

		final reloadButtonContainer = document.createSpanElement();
		reloadButtonContainer.appendChild(document.createTextNode("; "));
		reloadButtonContainer.appendChild(reloadButton);
		legend.appendChild(reloadButtonContainer);

		legend.appendChild(document.createTextNode(")"));
		
		syncState = function() {

			final canCleanUp = (p.data?.cleanup != null);
			final enabled = PluginManager.isEnabled(p.name);

			p_label.classList.setTokenFlag("error", p.error != null);
			
			if (p.error != null) {
				p_label.style.pointerEvents = "";
				p_label.title = Std.string(p.error);
			} else p_label.style.pointerEvents = "none";

			reloadButtonContainer.setDisplayFlag(enabled && (p.data == null || canCleanUp));

			var desc = p.config.description;
			if (desc != null && NativeString.trimBoth(desc) == "") desc = null;
			if (desc != null) p_desc.setInnerText(desc);

			toggleButton.textContent = (enabled) 
				? "disable" 
				: "enable";
				
			toggleButton.title = (enabled && !canCleanUp)
				? "Requires a restart."
				: "";

			group.setGroupVisibility(enabled);
			
			if (enabled) {
				if (p.data.buildPreferences != null) {
					p.data.buildPreferences(p_conf);
				}
			}

		}

		syncState();
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