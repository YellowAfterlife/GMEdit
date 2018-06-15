/// compiled via Babel
'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

(function () {
  var isNodeContext = false;
  if (isNodeContext) {
    Draggabilly = global.Draggabilly;
  }

  var tabTemplate = '\n    <div class="chrome-tab">\n      <div class="chrome-tab-background">\n        <svg version="1.1" xmlns="http://www.w3.org/2000/svg"><defs><symbol id="topleft" viewBox="0 0 214 29" ><path d="M14.3 0.1L214 0.1 214 29 0 29C0 29 12.2 2.6 13.2 1.1 14.3-0.4 14.3 0.1 14.3 0.1Z"/></symbol><symbol id="topright" viewBox="0 0 214 29"><use xlink:href="#topleft"/></symbol><clipPath id="crop"><rect class="mask" width="100%" height="100%" x="0"/></clipPath></defs><svg width="50%" height="100%" transfrom="scale(-1, 1)"><use xlink:href="#topleft" width="214" height="29" class="chrome-tab-background"/><use xlink:href="#topleft" width="214" height="29" class="chrome-tab-shadow"/></svg><g transform="scale(-1, 1)"><svg width="50%" height="100%" x="-100%" y="0"><use xlink:href="#topright" width="214" height="29" class="chrome-tab-background"/><use xlink:href="#topright" width="214" height="29" class="chrome-tab-shadow"/></svg></g></svg>\n      </div>\n      <div class="chrome-tab-favicon"></div>\n      <div class="chrome-tab-title"><span class="chrome-tab-title-text"></span></div>\n      <div class="chrome-tab-close"></div>\n    </div>\n  ';

  var defaultTapProperties = {
    title: '',
    favicon: ''
  };

  var instanceId = 0;

  var ChromeTabs = function () {
    function ChromeTabs() {
      _classCallCheck(this, ChromeTabs);

      this.draggabillyInstances = [];
    }

    _createClass(ChromeTabs, [{
      key: 'init',
      value: function init(el, options) {
        this.el = el;
        this.options = options;

        this.instanceId = instanceId;
        this.el.setAttribute('data-chrome-tabs-instance-id', this.instanceId);
        instanceId += 1;

        this.setupStyleEl();
        this.setupEvents();
        this.layoutTabs();
        this.fixZIndexes();
        this.setupDraggabilly();
      }
    }, {
      key: 'emit',
      value: function emit(eventName, data) {
        return this.el.dispatchEvent(new CustomEvent(eventName, { detail: data }));
      }
    }, {
      key: 'setupStyleEl',
      value: function setupStyleEl() {
        this.animationStyleEl = document.createElement('style');
        this.el.appendChild(this.animationStyleEl);
      }
    }, {
      key: 'setupEvents',
      value: function setupEvents() {
        var _this = this;

        window.addEventListener('resize', function (event) {
          return _this.layoutTabs();
        });

        //this.el.addEventListener('dblclick', event => this.addTab())
        this.el.addEventListener('mouseup', function (_ref) {
          var which = _ref.which,
              target = _ref.target;

          if (which != 2) return;
          var tcl = target.classList;
          if (tcl.contains('chrome-tab') || tcl.contains('chrome-tab-close') || tcl.contains('chrome-tab-title') || tcl.contains('chrome-tab-title-text') || tcl.contains('chrome-tab-favicon')) {
            var tab = tcl.contains('chrome-tab') ? target : target.parentElement;
            if (tcl.contains('chrome-tab-title-text')) tab = tab.parentElement;
            if (tab) tab.querySelector('.chrome-tab-close').click();
          }
        });

        this.el.addEventListener('click', function (_ref2) {
          var target = _ref2.target;

          if (target.classList.contains('chrome-tab')) {
            _this.setCurrentTab(target);
          } else if (target.classList.contains('chrome-tab-close')) {
            var e = new CustomEvent('tabClose', { cancelable: true, detail: { tabEl: target.parentNode } });
            if (_this.el.dispatchEvent(e)) _this.removeTab(target.parentNode);
          } else if (target.classList.contains('chrome-tab-title') || target.classList.contains('chrome-tab-title-text') || target.classList.contains('chrome-tab-favicon')) {
            _this.setCurrentTab(target.parentNode);
          }
        });
      }
    }, {
      key: 'layoutTabs',
      value: function layoutTabs() {
        var _this2 = this;

        var tabWidth = this.tabWidth;

        this.cleanUpPreviouslyDraggedTabs();
        this.tabEls.forEach(function (tabEl) {
          return tabEl.style.width = tabWidth + 'px';
        });
        requestAnimationFrame(function () {
          var styleHTML = '';
          // +y: round x
          _this2.tabPositions.forEach(function (left, i) {
            styleHTML += '\n            .chrome-tabs[data-chrome-tabs-instance-id="' + _this2.instanceId + '"] .chrome-tab:nth-child(' + (i + 1) + ') {\n              transform: translate3d(' + (left | 0) + 'px, 0, 0)\n            }\n          ';
          });
          _this2.animationStyleEl.innerHTML = styleHTML;
        });
      }
    }, {
      key: 'fixZIndexes',
      value: function fixZIndexes() {
        var bottomBarEl = this.el.querySelector('.chrome-tabs-bottom-bar');
        var tabEls = this.tabEls;

        tabEls.forEach(function (tabEl, i) {
          var zIndex = tabEls.length - i;

          if (tabEl.classList.contains('chrome-tab-current')) {
            bottomBarEl.style.zIndex = tabEls.length + 1;
            zIndex = tabEls.length + 2;
          }
          tabEl.style.zIndex = zIndex;
        });
      }
    }, {
      key: 'createNewTabEl',
      value: function createNewTabEl() {
        var div = document.createElement('div');
        div.innerHTML = tabTemplate;
        return div.firstElementChild;
      }
    }, {
      key: 'addTab',
      value: function addTab(tabProperties) {
        var tabEl = this.createNewTabEl();

        tabEl.classList.add('chrome-tab-just-added');
        setTimeout(function () {
          return tabEl.classList.remove('chrome-tab-just-added');
        }, 500);

        tabProperties = Object.assign({}, defaultTapProperties, tabProperties);
        this.tabContentEl.appendChild(tabEl);
        this.updateTab(tabEl, tabProperties);
        this.emit('tabAdd', { tabEl: tabEl });
        this.setCurrentTab(tabEl);
        this.layoutTabs();
        this.fixZIndexes();
        this.setupDraggabilly();
      }
    }, {
      key: 'setCurrentTab',
      value: function setCurrentTab(tabEl) {
        var currentTab = this.el.querySelector('.chrome-tab-current');
        if (currentTab) currentTab.classList.remove('chrome-tab-current');
        tabEl.classList.add('chrome-tab-current');
        this.fixZIndexes();
        this.emit('activeTabChange', { tabEl: tabEl });
      }
    }, {
      key: 'removeTab',
      value: function removeTab(tabEl) {
        /*if (tabEl.classList.contains('chrome-tab-current')) {
          if (tabEl.previousElementSibling) {
            this.setCurrentTab(tabEl.previousElementSibling)
          } else if (tabEl.nextElementSibling) {
            this.setCurrentTab(tabEl.nextElementSibling)
          }
        }*/ // +y: handled on Haxe side instead
        var prevTab = tabEl.previousElementSibling;
        var nextTab = tabEl.nextElementSibling;
        tabEl.parentNode.removeChild(tabEl);
        this.emit('tabRemove', { tabEl: tabEl, prevTab: prevTab, nextTab: nextTab });
        this.layoutTabs();
        this.fixZIndexes();
        this.setupDraggabilly();
      }
    }, {
      key: 'updateTab',
      value: function updateTab(tabEl, tabProperties) {
        tabEl.querySelector('.chrome-tab-title-text').textContent = tabProperties.title;
        tabEl.querySelector('.chrome-tab-favicon').style.backgroundImage = 'url(\'' + tabProperties.favicon + '\')';
      }
    }, {
      key: 'cleanUpPreviouslyDraggedTabs',
      value: function cleanUpPreviouslyDraggedTabs() {
        this.tabEls.forEach(function (tabEl) {
          return tabEl.classList.remove('chrome-tab-just-dragged');
        });
      }
    }, {
      key: 'setupDraggabilly',
      value: function setupDraggabilly() {
        var _this3 = this;

        var tabEls = this.tabEls;
        var tabEffectiveWidth = this.tabEffectiveWidth;
        var tabPositions = this.tabPositions;

        this.draggabillyInstances.forEach(function (draggabillyInstance) {
          return draggabillyInstance.destroy();
        });

        tabEls.forEach(function (tabEl, originalIndex) {
          var originalTabPositionX = tabPositions[originalIndex];
          var draggabillyInstance = new Draggabilly(tabEl, {
            axis: 'x',
            containment: _this3.tabContentEl
          });

          _this3.draggabillyInstances.push(draggabillyInstance);

          draggabillyInstance.on('dragStart', function () {
            _this3.cleanUpPreviouslyDraggedTabs();
            tabEl.classList.add('chrome-tab-currently-dragged');
            _this3.el.classList.add('chrome-tabs-sorting');
            _this3.fixZIndexes();
          });

          draggabillyInstance.on('dragEnd', function () {
            var finalTranslateX = parseFloat(tabEl.style.left, 10);
            tabEl.style.transform = 'translate3d(0, 0, 0)';

            // Animate dragged tab back into its place
            requestAnimationFrame(function () {
              tabEl.style.left = '0';
              tabEl.style.transform = 'translate3d(' + finalTranslateX + 'px, 0, 0)';

              requestAnimationFrame(function () {
                tabEl.classList.remove('chrome-tab-currently-dragged');
                _this3.el.classList.remove('chrome-tabs-sorting');

                _this3.setCurrentTab(tabEl);
                tabEl.classList.add('chrome-tab-just-dragged');

                requestAnimationFrame(function () {
                  tabEl.style.transform = '';

                  _this3.setupDraggabilly();
                });
              });
            });
          });

          draggabillyInstance.on('dragMove', function (event, pointer, moveVector) {
            // Current index be computed within the event since it can change during the dragMove
            var tabEls = _this3.tabEls;
            var currentIndex = tabEls.indexOf(tabEl);

            var currentTabPositionX = originalTabPositionX + moveVector.x;
            var destinationIndex = Math.max(0, Math.min(tabEls.length, Math.floor((currentTabPositionX + tabEffectiveWidth / 2) / tabEffectiveWidth)));

            if (currentIndex !== destinationIndex) {
              _this3.animateTabMove(tabEl, currentIndex, destinationIndex);
            }
          });
        });
      }
    }, {
      key: 'animateTabMove',
      value: function animateTabMove(tabEl, originIndex, destinationIndex) {
        if (destinationIndex < originIndex) {
          tabEl.parentNode.insertBefore(tabEl, this.tabEls[destinationIndex]);
        } else {
          tabEl.parentNode.insertBefore(tabEl, this.tabEls[destinationIndex + 1]);
        }
      }
    }, {
      key: 'tabEls',
      get: function get() {
        return Array.prototype.slice.call(this.el.querySelectorAll('.chrome-tab'));
      }
    }, {
      key: 'tabContentEl',
      get: function get() {
        return this.el.querySelector('.chrome-tabs-content');
      }
    }, {
      key: 'tabWidth',
      get: function get() {
        var tabsContentWidth = this.tabContentEl.clientWidth - this.options.tabOverlapDistance;
        var width = tabsContentWidth / this.tabEls.length + this.options.tabOverlapDistance;
        return Math.max(this.options.minWidth, Math.min(this.options.maxWidth, width));
      }
    }, {
      key: 'tabEffectiveWidth',
      get: function get() {
        return this.tabWidth - this.options.tabOverlapDistance;
      }
    }, {
      key: 'tabPositions',
      get: function get() {
        var tabEffectiveWidth = this.tabEffectiveWidth;
        var left = 0;
        var positions = [];

        this.tabEls.forEach(function (tabEl, i) {
          positions.push(left);
          left += tabEffectiveWidth;
        });
        return positions;
      }
    }]);

    return ChromeTabs;
  }();

  if (isNodeContext) {
    module.exports = ChromeTabs;
  } else {
    window.ChromeTabs = ChromeTabs;
  }
})();