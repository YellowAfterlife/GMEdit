const Preferences = $gmedit['ui.Preferences'];

window.__gm_docs_tooltips = {
  enabled: true,
  replaced: false,
  replacedText: '',
  preReplacement: '',
  keys: [],
  timer: -1
};

GMEdit.register('docs-tooltips', {
  init: () => {
    if (!Preferences.current.docs_tooltips) Preferences.current.docs_tooltips = { enabled: true };
    window.__gm_docs_tooltips.enabled = Preferences.current.docs_tooltips.enabled;
    window.__gm_docs_tooltips.timer = createTimer();
  },
  cleanup: () => {
    clearInterval(window.__gm_docs_tooltips.timer);
  }
});

GMEdit.on('preferencesBuilt', function(e) {
  var out = e.target.querySelector('.plugin-settings[for="docs-tooltips"]');

  Preferences.addCheckbox(out, 'Enabled', window.__gm_docs_tooltips.enabled, () => {
    window.__gm_docs_tooltips.enabled = !window.__gm_docs_tooltips.enabled;
    Preferences.current.docs_tooltips.enabled = window.__gm_docs_tooltips.enabled;
    Preferences.save();
  });
});

fetch('https://raw.githubusercontent.com/christopherwk210/gm-bot/master/static/docs-index.json')
.then(res => res.json())
.then(data => window.__gm_docs_tooltips.keys = data.keys)
.catch(() => console.error('docs-tooltips: failed to fetch documentation'))

function getTooltipText() {
  if (aceEditor.tooltipManager.ttip.$element) return aceEditor.tooltipManager.ttip.$element.innerHTML;
}

function setTooltipText(html = '') {
  if (aceEditor.tooltipManager.ttip.$element) aceEditor.tooltipManager.ttip.$element.innerHTML = html;
}

function createTimer() {
  return setInterval(() => {
    if (!window.__gm_docs_tooltips.enabled) return;

    if (aceEditor.tooltipManager.ttip.isOpen) {
      if (getTooltipText() !== window.__gm_docs_tooltips.replacedText) window.__gm_docs_tooltips.replaced = false;
  
      if (!window.__gm_docs_tooltips.replaced) {
        const existingText = getTooltipText();
        const keyName = existingText.split('(')[0];
        const returnValue = existingText.split('➜')[1];
  
        const foundItem = window.__gm_docs_tooltips.keys.find(item => item.name === keyName);
        if (foundItem && foundItem.topics.length === 1) {
          const key = foundItem;
          const text = createTooltipHTML(key, returnValue);
  
          window.__gm_docs_tooltips.replaced = true;
          window.__gm_docs_tooltips.replacedText = text;
          window.__gm_docs_tooltips.preReplacement = existingText;
          setTooltipText(window.__gm_docs_tooltips.replacedText);
        }
      }
    } else {
      window.__gm_docs_tooltips.replaced = false;
      window.__gm_docs_tooltips.replacedText = '';
      setTooltipText(window.__gm_docs_tooltips.preReplacement)
    }
  }, 100);
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