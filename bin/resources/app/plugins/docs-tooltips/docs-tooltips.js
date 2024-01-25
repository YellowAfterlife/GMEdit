(() => {
  const Preferences = $gmedit['ui.Preferences'];
  
  const state = {
    enabled: true,
    strictLatest: false,
    keys: []
  };
  
  GMEdit.register('docs-tooltips', {
    init: () => {
      downloadLatestDocs();

      if (!Preferences.current.docs_tooltips) Preferences.current.docs_tooltips = {
        enabled: true,
        strictLatest: false,
        keys: []
      };

      state.enabled = Preferences.current.docs_tooltips.enabled;
      state.strictLatest = Preferences.current.docs_tooltips.strictLatest;
      state.keys = Preferences.current.docs_tooltips.keys;

      const ogSetText = aceEditor.tooltipManager.ttip.setText;
      aceEditor.tooltipManager.ttip.setText = function() {
        if (!state.enabled
          || (state.strictLatest && $gmedit['gml.Project'].current.version.name != 'v23')
          || state.keys == null
        ) {
          ogSetText.apply(this, arguments);
          return;
        }

        const text = arguments[0];
        const returnValue = text.split('➜')[1];

        const foundItem = state.keys.find(item => item.name === text.split('(')[0]);
        if (foundItem && foundItem.topics.length === 1) {
          const key = foundItem;
          const html = createTooltipHTML(key, returnValue);

          aceEditor.tooltipManager.ttip.setHtml.apply(this, [html]);
        } else {
          ogSetText.apply(this, arguments);
        }
      }
    },
    cleanup: () => {}
  });
  
  GMEdit.on('preferencesBuilt', function(e) {
    var out = e.target.querySelector('.plugin-settings[for="docs-tooltips"]');
  
    Preferences.addCheckbox(out, 'Enabled', state.enabled, () => {
      state.enabled = !state.enabled;
      Preferences.current.docs_tooltips.enabled = state.enabled;
      Preferences.save();
    });

    Preferences.addCheckbox(out, 'Disable for non GMS2.3+ projects', state.strictLatest, () => {
      state.strictLatest = !state.strictLatest;
      Preferences.current.docs_tooltips.strictLatest = state.strictLatest;
      Preferences.save();
    });
  });

  function downloadLatestDocs() {
    fetch('https://raw.githubusercontent.com/christopherwk210/gm-bot/master/static/docs-index.json')
      .then(res => res.json())
      .then(data => {
        state.keys = data.keys;
        Preferences.current.docs_tooltips.keys = data.keys;
        Preferences.save();
      })
      .catch(() => console.error('docs-tooltips: failed to fetch documentation'));
  }
  
  function createTooltipHTML(key, returnValue) {
    const topic = key.topics[0];
  
    const title = key.name === topic.name ? (topic.syntax || key.name) : `${key.name} - ${topic.name}`;
  
    let description = `<p>${topic.blurb}</p>`;
    if (topic.args && topic.args.length) {
      description += `<div style="margin-bottom: 0.25em; border-bottom: 1px solid #495057;">Arguments</div>`;
      for (const arg of topic.args) {
        description += `<div style="margin-bottom: 0.25em"><strong style="color: #039E5C;">${arg.argument}</strong>: ${arg.description.replace('`OPTIONAL`', '(Optional)')}</div>`;
      }
    }
  
    let text = `<h4 style="color: #FFB871; margin: 0; border-bottom: 1px solid #495057; padding-bottom: 8px;">${title}➜${returnValue}</h4>`;
  
    text += '<div style="max-width: 400px; white-space: normal;">';
    text += description;
    text += '</div>';
  
    return text;
  }
})();