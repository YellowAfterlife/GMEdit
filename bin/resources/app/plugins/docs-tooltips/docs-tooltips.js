
/**
 * @typedef ManualEntry
 * @prop {string} name
 * @prop {ManualPage[]} pages
 */

/**
 * @typedef ManualPage
 * @prop {string} title
 * @prop {string} blurb
 * @prop {string} url
 * @prop {string} syntax
 * @prop {ManualArg[]} args
 */

/**
 * @typedef ManualArg
 * @prop {string} argument
 * @prop {string} description
 */

(() => {
  const Preferences = $gmedit['ui.Preferences'];
  const ProjectProperties = $gmedit['ui.project.ProjectProperties'];
  const Project = $gmedit['gml.Project'];

  const ogSetText = aceEditor.tooltipManager.ttip.setText;

  /** @type {Record<string, ManualEntry>} */
  let keys = {};

  GMEdit.register('docs-tooltips', {
    init: () => {

      if (!Preferences.current.docs_tooltips) Preferences.current.docs_tooltips = {
        strictLatest: false,
        keys: {}
      };

      keys = Preferences.current.docs_tooltips.keys;

      downloadLatestDocs();

      aceEditor.tooltipManager.ttip.setText = function() {

        const project = Project.current;

        if (project == null || !isEnabled(project)) {
          ogSetText.apply(this, arguments);
          return;
        }

        const text = arguments[0];
        const returnValue = text.split('➜')[1];

        const foundItem = Object.values(keys).find(item => {
          if (text.includes('>(')) {
            return item.name === text.split('<')[0];
          } else {
            return item.name === text.split('(')[0];
          }
        });
        
        if (foundItem && foundItem.pages.length === 1) {
          const key = foundItem;
          const html = createTooltipHTML(key, returnValue, text);

          aceEditor.tooltipManager.ttip.setHtml.call(this, html);
        } else {
          ogSetText.apply(this, arguments);
        }

      };

    },
    cleanup: () => {
      aceEditor.tooltipManager.ttip.setText = ogSetText;
    },
    buildPreferences: (out) => {
  
      Preferences.addCheckbox(out, 'Disable for non GMS2.3+ projects', isStrict23(), (strict23) => {
        Preferences.current.docs_tooltips.strictLatest = strict23;
        Preferences.save();
      });

    },
    buildProjectProperties: (out, project) => {

      Preferences.addCheckbox(out, 'Disable for this project', projectHasDisabled(project), (disabled) => {

        const properties = project.properties;
        properties.docs_tooltips ??= {};
        properties.docs_tooltips.disabled = disabled;

        ProjectProperties.save(project, properties);
        
      });

    }
  });

  /**
   * Returns whether tooltips should be used for the given project.
   * @returns {boolean}
   */
  function isEnabled(project) {
    return !projectHasDisabled(project)
        && (project.isGMS23 || !isStrict23())
        && (keys != null);
  }

  /**
   * Returns whether the given project has explicitly disabled tooltips.
   * @returns {boolean}
   */
  function projectHasDisabled(project) {
    return (project.properties?.docs_tooltips?.disabled) == true;
  }

  /**
   * Returns whether strict GMv2.3+ mode is enabled.
   * @returns {boolean}
   */
  function isStrict23() {
    return (Preferences.current.docs_tooltips?.strictLatest) == true;
  }

  function downloadLatestDocs() {
    fetch('https://raw.githubusercontent.com/christopherwk210/gm-bot/master/static/docs-index.json')
      .then(res => res.json())
      .then(data => {
        keys = data;
        Preferences.current.docs_tooltips.keys = data;
        Preferences.save();
      })
      .catch(() => console.error('docs-tooltips: failed to fetch documentation'));
  }
  
  /**
   * 
   * @param {ManualEntry} key 
   * @param {string} returnValue 
   * @param {string} originalText 
   * @returns 
   */
  function createTooltipHTML(key, returnValue, originalText) {
    const topic = key.pages[0];
  
    let title = topic.syntax || key.name;
  
    let description = `<p>${topic.blurb}</p>`;
    if (topic.args && topic.args.length) {
      description += `<div style="margin-bottom: 0.25em; border-bottom: 1px solid #495057;">Arguments</div>`;
      for (const arg of topic.args) {
        description += `<div style="margin-bottom: 0.25em"><strong style="color: #039E5C;">${arg.argument}</strong>: ${arg.description.replace('`OPTIONAL`', '(Optional)')}</div>`;
      }
    }

    if (title.includes('(')) {
      let genericMatches = originalText.match(/(<\S+>)/g);
      if (genericMatches) {
        let generic = genericMatches[0];
        generic = generic.replace('<', '&lt;').replace('>', '&gt;');
        title = title.replace('(', generic + '(');
      }
    }
  
    let text = `<h4 style="color: #FFB871; margin: 0; border-bottom: 1px solid #495057; padding-bottom: 8px;">${title}➜${returnValue}</h4>`;
  
    text += '<div style="max-width: 400px; white-space: normal;">';
    text += description;
    text += '</div>';
  
    return text;
  }
})();