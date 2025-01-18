package ui.preferences;
import js.html.SpanElement;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.LabelElement;
import js.html.FieldSetElement;
import js.html.LegendElement;
import js.html.Element;
import js.html.Console;
import tools.NativeString;
import ui.Preferences.*;
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

	public static function build(parent:Element) {
		
		final group = addGroup(parent, "Plugins");
		group.id = "pref-plugins";
		
		final legend:LegendElement = group.querySelectorAuto("legend");
		legend.appendChild(document.createTextNode(" ("));
		legend.append(createShellAnchor("https://github.com/GameMakerDiscord/GMEdit/wiki/Using-plugins", "wiki"));
		
		if (FileSystem.canSync) {
			legend.appendChild(document.createTextNode("; "));
			legend.append(createShellAnchor(FileWrap.userPath + "/plugins", "manage"));
		}
		
		legend.appendChild(document.createTextNode(")"));

		addText(group, "Currently loaded plugins:");

		for (_ => p in PluginManager.registry) {
			p.prefItem = new PluginPrefItemImpl(group, p);
		}
		
	}

}

interface PluginPrefItem {
	/**
		Sync preferences visual state with the underlying plugin state.
	**/
	public function sync(): Void;
}

class PluginPrefItemImpl implements PluginPrefItem {

	final p:PluginState;

	final group:FieldSetElement;
	final legend:LegendElement;
	final p_label:LabelElement = document.createLabelElement();
	final p_desc:DivElement = document.createDivElement();
	final p_conf:Element = document.createDivElement();

	final openButton:AnchorElement;
	final toggleButton:AnchorElement;
	final toggleButtonContainer:SpanElement;
	final reloadButton:AnchorElement;
	final reloadButtonContainer:SpanElement;
	
	public function new(out:Element, pluginState:PluginState) {

		p = pluginState;

		group = addGroup(out, "");
		legend = group.querySelectorAuto("legend");
		group.classList.add("plugin-info");
		group.setAttribute("for", p.name);
		
		p_label.appendChild(document.createTextNode(p.name));
		legend.appendChild(p_label);

		p_desc.classList.add("plugin-description");
		group.appendChild(p_desc);

		p_conf.classList.add("plugin-settings");
		p_conf.setAttribute("for", p.name);
		group.appendChild(p_conf);

		legend.appendChild(document.createTextNode("("));
		
		openButton = createShellAnchor(p.path, "open");
		legend.appendChild(openButton);

		toggleButton = createFuncAnchor("", function(_) toggle());

		toggleButtonContainer = document.createSpanElement();
		toggleButtonContainer.appendChild(document.createTextNode("; "));
		toggleButtonContainer.appendChild(toggleButton);
		legend.appendChild(toggleButtonContainer);

		reloadButton = createFuncAnchor("reload", function(_) reload());

		reloadButtonContainer = document.createSpanElement();
		reloadButtonContainer.appendChild(document.createTextNode("; "));
		reloadButtonContainer.appendChild(reloadButton);
		legend.appendChild(reloadButtonContainer);

		legend.appendChild(document.createTextNode(")"));
		
		sync();

	}

	public function sync(): Void {

		final enabled = PluginManager.isEnabled(p.config.name);

		p_label.classList.setTokenFlag("error", p.error != null);
		
		if (p.error != null) {
			p_label.style.pointerEvents = "";
			p_label.title = Std.string(p.error);
		} else p_label.style.pointerEvents = "none";

		reloadButtonContainer.setDisplayFlag(enabled && (p.data == null || p.canCleanUp));

		var desc = p.config.description;
		if (desc != null && NativeString.trimBoth(desc) == "") desc = null;
		if (desc != null) p_desc.setInnerText(desc);

		toggleButton.textContent = (enabled) 
			? "disable" 
			: "enable";
			
		toggleButton.title = (enabled && !p.canCleanUp)
			? "Requires a restart."
			: "";

		group.setGroupVisibility(enabled);

		if (p.canCleanUp) {
			p_conf.clearInner();
		}
		
		if (p.data?.buildPreferences != null) {
			if (enabled) {
				p.data.buildPreferences(p_conf);
			}
		}

	}

	/**
		Toggle whether the linked plugin is enabled.
	**/
	function toggle() {
		if (PluginManager.isEnabled(p.config.name)) {
			PluginManager.disable(p.config.name);
		} else {
			PluginManager.enable(p.config.name);
		}
	}

	/**
		Reload the linked plugin from disk.
	**/
	function reload() {
		PluginManager.reload(p).then(function(_) {
			sync();
		});
	}

}
