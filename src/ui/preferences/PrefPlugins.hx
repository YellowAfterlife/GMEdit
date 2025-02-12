package ui.preferences;
import gml.Project;
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

	static final prefGroups:Map<PluginState, PrefsGroup> = new Map();
	static final propGroups:Map<PluginState, ProjectPropsGroup> = new Map();

	/**
		Re-sync the preferences state for the provided plugin.
	**/
	public static function sync(plugin:PluginState) {

		final prefGroup = prefGroups[plugin];
		
		if (prefGroup != null) {
			prefGroup.sync();
		}

		final propGroup = propGroups[plugin];

		if (propGroup != null) {
			propGroup.sync();
		}

	}

	/**
		Build and append preference groups for loaded plugins.
	**/
	public static function buildPreferences(parent:Element) {
		
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

		for (p in PluginManager.knownPlugins) {
			prefGroups[p] = new PrefsGroup(group, p);
		}
		
	}

	/**
		Build project-properties groups for loaded plugins. Plugins which do not implement
		`PluginData.buildProjectProperties` will not have their group appended.
	**/
	public static function buildProjectProperties(parent:Element, project:Project) {
		for (plugin in PluginManager.knownPlugins) {
			
			var propGroup = propGroups[plugin];

			if (propGroup == null) {
				propGroup = new ProjectPropsGroup(plugin);
				propGroups[plugin] = propGroup;
			}

			propGroup.project = project;
			propGroup.sync();

		}
	}

}

private class PrefsGroup {

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

		legend.appendChild(document.createTextNode(" ("));
		
		openButton = createShellAnchor(p.dir, "open");
		legend.appendChild(openButton);

		toggleButton = createFuncAnchor("", _ -> toggle());

		toggleButtonContainer = document.createSpanElement();
		toggleButtonContainer.appendChild(document.createTextNode("; "));
		toggleButtonContainer.appendChild(toggleButton);
		legend.appendChild(toggleButtonContainer);

		reloadButton = createFuncAnchor("reload", _ -> reload());

		reloadButtonContainer = document.createSpanElement();
		reloadButtonContainer.appendChild(document.createTextNode("; "));
		reloadButtonContainer.appendChild(reloadButton);
		legend.appendChild(reloadButtonContainer);

		legend.appendChild(document.createTextNode(")"));
		
		sync();

	}

	public function sync(): Void {
		
		final config = p.config;
		final enabled = (config == null) || PluginManager.isEnabled(p);

		p_label.classList.setTokenFlag("error", p.error != null);
		
		if (p.error != null) {
			p_label.style.pointerEvents = "";
			p_label.title = Std.string(p.error);
		} else p_label.style.pointerEvents = "none";

		reloadButtonContainer.setDisplayFlag(enabled && (p.data == null || p.canCleanUp));

		if (config != null) {
			final desc = config.description;
			
			if (desc != null && NativeString.trimBoth(desc) != "") {
				p_desc.setInnerText(desc);
			}
		}

		toggleButton.textContent = (enabled) 
			? "disable" 
			: "enable";

		toggleButton.title = (enabled && !p.canCleanUp)
			? "Requires a restart."
			: "";
		
		toggleButtonContainer.setDisplayFlag(config != null);
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
		if (PluginManager.isEnabled(p)) {
			PluginManager.disable(p);
		} else {
			PluginManager.enable(p);
		}
	}

	/**
		Reload the linked plugin from disk.
	**/
	function reload() {
		PluginManager.reload(p).then(_ -> sync());
	}

}

private class ProjectPropsGroup {

	public var project:Null<Project> = null;

	final p:PluginState;
	final group:FieldSetElement;
	final content:Element = document.createDivElement();

	public function new(plugin:PluginState) {
		p = plugin;
		group = createGroup(p.name);
		group.appendChild(content);
	}

	public function sync() {

		content.clearInner();

		if ((project == null)
			|| (p.error != null)
			|| !PluginManager.isEnabled(p)
			|| (p.data.buildProjectProperties == null)
		) {
			group.remove();
			return;
		}

		p.data.buildProjectProperties(content, project);

		if (group.parentElement != project.propertiesElement) {
			group.remove();
			project.propertiesElement.appendChild(group);
		}

	}

}
