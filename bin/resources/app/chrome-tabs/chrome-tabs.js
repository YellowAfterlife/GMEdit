(function(){
  const isNodeContext = false
  if (isNodeContext) {
    Draggabilly = global.Draggabilly;
  }

  const tabTemplate = `
    <div class="chrome-tab">
      <div class="chrome-tab-background">
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <symbol id="topleft" viewBox="0 0 214 29" >
              <path class="curvy" d="M14.3 0.1L214 0.1 214 29 0 29C0 29 12.2 2.6 13.2 1.1 14.3-0.4 14.3 0.1 14.3 0.1Z"/>
              <rect class="flat" width="210" height="29" x="7"/>
            </symbol>
            <symbol id="topleft-pinline">
              <path class="curvy pinned" d="M 14.162109 0.037109375 C 14.024609 0.099609375 13.749219 0.34960938 13.199219 1.0996094 C 13.154145 1.1672199 12.840393 1.8359117 12.751953 2 L 214 2 L 214 0.099609375 L 14.300781 0.099609375 C 14.300781 0.099609375 14.299609 -0.025390625 14.162109 0.037109375 z " />
              <rect class="flat pinned" width="210" height="2" x="7"/>
            </symbol>
            <symbol id="topright" viewBox="0 0 214 29">
              <use xlink:href="#topleft"/>
            </symbol>
            <symbol id="topright-pinline" viewBox="0 0 214 29">
              <use xlink:href="#topleft-pinline"/>
            </symbol>
            <clipPath id="crop">
              <rect class="mask" width="100%" height="100%" x="0"/>
            </clipPath>
            <filter style="color-interpolation-filters:sRGB;" id="drop-highlight">
              <feBlend mode="normal" in2="SourceGraphic" id="feBlend1156" result="result1" />
              <feColorMatrix id="feColorMatrix1167" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 1 0" result="fbSourceGraphic" />
              <feColorMatrix result="fbSourceGraphicAlpha" in="fbSourceGraphic" values="0 0 0 -1 0 0 0 0 -1 0 0 0 0 -1 0 0 0 0 1 0" id="feColorMatrix1233" />
              <feFlood id="feFlood1235" flood-opacity="0.498039" flood-color="rgb(153,193,241)" result="flood" in="fbSourceGraphic" />
              <feComposite in2="fbSourceGraphic" id="feComposite1237" in="flood" operator="in" result="composite1" />
              <feComposite in2="result1" id="feComposite1243" operator="over" result="composite2" />
            </filter>
          </defs>
          <svg width="51%" height="100%" transfrom="scale(-1, 1)">
            <use xlink:href="#topleft" width="214" height="29" class="chrome-tab-background"/>
            <use xlink:href="#topleft-pinline" width="214" height="29" class="chrome-tab-pinline"/>
            <use xlink:href="#topleft" width="214" height="29" class="chrome-tab-shadow"/>
          </svg>
          <g transform="scale(-1, 1)"><svg width="50%" height="100%" x="-100%" y="0">
            <use xlink:href="#topright" width="214" height="29" class="chrome-tab-background"/>
            <use xlink:href="#topright-pinline" width="214" height="29" class="chrome-tab-pinline"/>
            <use xlink:href="#topright" width="214" height="29" class="chrome-tab-shadow"/>
          </svg></g>
        </svg>
      </div>
      <div class="chrome-tab-favicon"></div>
      <div class="chrome-tab-title"><span class="chrome-tab-title-text"></span></div>
      <div class="chrome-tab-close"></div>
    </div>
  `

  const defaultTapProperties = {
    title: '',
    favicon: ''
  }

  let instanceId = 0
  
  function setDatasetValue(el, key, value) {
    if (value == null) {
      if (el.dataset[key] == null) return false
      delete el.dataset[key]
      return true
    } else {
      value = "" + value
      if (el.dataset[key] == value) return false
      el.dataset[key] = value
      return true
    }
  }
  function setTokenFlag(list, key, value) {
    if (value) {
      if (!list.contains(key)) list.add(key)
    } else {
      if (list.contains(key)) list.remove(key)
    }
  }

  class ChromeTabs {
    constructor() {
      this.draggabillyInstances = []
    }

    init(el, options) {
      this.el = el
      this.options = options

      this.instanceId = instanceId
      this.el.setAttribute('data-chrome-tabs-instance-id', this.instanceId)
      instanceId += 1

      this.setupStyleEl()
      this.setupEvents()
      this.layoutTabs()
      this.fixZIndexes()
      this.setupDraggabilly()
      this.tabHeight = 28
    }

    emit(eventName, data) {
      return this.el.dispatchEvent(new CustomEvent(eventName, { detail: data }))
    }

    setupStyleEl() {
      this.animationStyleEl = document.createElement('style')
      this.el.appendChild(this.animationStyleEl)
    }
    
    getTabPinLayer(tabEl) {
      return tabEl.classList.contains("chrome-tab-pinned") ? (0|tabEl.dataset.pinLayer) : 0;
    }
    setTabPinLayer(target, pinLayer, move) {
      if (pinLayer > 0) {
        if (this.getTabPinLayer(target) == pinLayer) return;
        target.classList.add("chrome-tab-pinned");
        target.dataset.pinLayer = pinLayer;
      } else {
        if (!target.classList.contains("chrome-tab-pinned")) return;
        target.classList.remove("chrome-tab-pinned");
        delete target.dataset.pinLayer;
      }
      
      if (!move) return;
      let insertAfter = null;
      let tabEls = this.tabEls;
      for (let tabEl of tabEls) {
        if (tabEl == target) continue;
        let tabPinLayer = this.getTabPinLayer(tabEl);
        if (tabPinLayer >= pinLayer) insertAfter = tabEl;
      }
      if (insertAfter) {
        insertAfter.after(target);
      } else {
        if (target != tabEls[0]) tabEls[0].before(target);
      }
    }

    setupEvents() {
      window.addEventListener('resize', event => {
        if (!this.ignoreResize) this.layoutTabs()
      })

      this.el.addEventListener('mousedown', (e) => {
        if (e.button == 1) {
          // have to preventDefault() on middle click or the browser might start scrolling the container when closing a tab
          e.preventDefault()
          return false
        }
      })
      
      this.el.addEventListener('mouseup', (e) => {
        if (e.button != 1) return;
        let target = e.target;
        let tcl = target.classList;
        if (tcl.contains('chrome-tab') || tcl.contains('chrome-tab-close') || tcl.contains('chrome-tab-title') || tcl.contains('chrome-tab-title-text') || tcl.contains('chrome-tab-favicon')) {
          let tab = tcl.contains('chrome-tab') ? target : target.parentElement;
          if (tcl.contains('chrome-tab-title-text')) tab = tab.parentElement;
          if (tab) tab.querySelector('.chrome-tab-close').click();
        }
        return false;
      })

      this.el.addEventListener('click', (e) => {
        let target = e.target
        if (target.classList.contains('chrome-tab')) {
          if (e.ctrlKey) { // pin/unpin
            this.setTabPinLayer(target, target.classList.contains("chrome-tab-pinned") ? 0 : 1, true)
            this.layoutTabs()
          } else this.setCurrentTab(target)
        } else if (target.classList.contains('chrome-tab-close')) {
          let e = new CustomEvent('tabClose', { cancelable: true, detail: { tabEl: target.parentNode } })
          if (this.el.dispatchEvent(e)) this.removeTab(target.parentNode)
        } else if (target.classList.contains('chrome-tab-title') || target.classList.contains('chrome-tab-title-text') || target.classList.contains('chrome-tab-favicon')) {
          this.setCurrentTab(target.parentNode)
        }
      })
    }

    get tabEls() {
      return Array.prototype.slice.call(this.el.querySelectorAll('.chrome-tab'))
    }

    get tabContentEl() {
      return this.el.querySelector('.chrome-tabs-content')
    }
    
    get tabsContentWidth() {
      return this.tabContentEl.clientWidth - this.options.tabOverlapDistance
    }

    get tabWidth() {
      const tabsContentWidth = this.tabsContentWidth
      const tabCount = this.tabEls.length
      const tabOverlapDistance = this.options.tabOverlapDistance
      let width = (tabsContentWidth / tabCount) + tabOverlapDistance
      const minWidth = this.options.minWidth
      const tabEffectiveMinWidth = minWidth - tabOverlapDistance
      width = Math.min(this.options.maxWidth, width)
      
      if (this.options.multiline && !this.options.fitText
        && tabEffectiveMinWidth * tabCount > tabsContentWidth
      ) {
        const tabsPerRow = Math.round(tabsContentWidth / tabEffectiveMinWidth)
        width = 0|(tabsContentWidth / tabsPerRow) + tabOverlapDistance
        //console.log({ tabsPerRow, tabsContentWidth, width })
        return width
      }
      return Math.max(minWidth, width)
    }

    get tabEffectiveWidth() {
      return this.tabWidth - this.options.tabOverlapDistance
    }

    get tabPositions() {
      let tabsContentWidth = this.tabsContentWidth
      const tabEls = this.tabEls
      const tabWidth = this.tabWidth
      let tabHeight, tabLeft = 0, tabRight = 0
      const first = tabEls[0]
      const autoHideCloseButtons = this.el.classList.contains("chrome-tabs-auto-hide-close-buttons")
      const lockPinned = this.el.classList.contains("chrome-tabs-lock-pinned")
      let closeButtonWidth = 0
      if (first) {
        tabHeight = first.offsetHeight
        tabLeft = parseInt(getComputedStyle(first.querySelector(".chrome-tab-favicon")).marginLeft)
        let closeBt = first.querySelector(".chrome-tab-close")
        tabRight = parseInt(getComputedStyle(closeBt).right)
        closeButtonWidth = closeBt.offsetWidth
      } else {
        tabHeight = this.el.querySelector(".chrome-tabs-content").offsetHeight
      }
      const multiline = this.options.multiline
      const rowBreakAfterPinnedTabs = multiline && this.options.rowBreakAfterPinnedTabs
      const fitText = multiline && this.options.fitText
      const multilineStretchStyle = multiline ? this.options.multilineStretchStyle : 0;
      const tabOverlapDistance = this.options.tabOverlapDistance
      let left = 0, top = 0
      let row = 0, column = 0
      let tabsPerRow = 0
      let maxTabsPerRow = 0
      let positions = []
      let overflow = false
      //console.log(tabEffectiveWidth, tabsContentWidth)
      
      let lastPinLayer = 0
      for (let tabEl of tabEls) {
        //console.log({ i, row, column, left, top, right: left + tabEffectiveWidth })
        let width
        if (fitText) {
          let titleText = tabEl.querySelector('.chrome-tab-title-text')
          if (!titleText) titleText = tabEl.querySelector('.chrome-tab-title')
          width = titleText.offsetWidth + tabLeft + tabRight + tabOverlapDistance
          if (autoHideCloseButtons) {
            // all close buttons are hidden
          } else if (tabEl.classList.contains("chrome-tab-pinned") && lockPinned) {
            // pinned tabs' close buttons are hidden
          } else width += closeButtonWidth
          width = Math.min(width, tabsContentWidth)
        } else width = tabWidth
        
        let lineBreak = false
        let fitToWidth = false
        if (multiline) {
          if (left + width > tabsContentWidth) {
            lineBreak = true
            fitToWidth = true
          } else if (rowBreakAfterPinnedTabs) {
            let pinLayer = this.getTabPinLayer(tabEl)
            if (pinLayer < lastPinLayer) lineBreak = true
            lastPinLayer = pinLayer
          }
        }
        if (lineBreak) {
          if (fitText && fitToWidth) {
            if (multilineStretchStyle == 2) {
              let pos = positions[positions.length - 1]
              pos.width = tabsContentWidth - pos.left
            } else if (multilineStretchStyle == 1) {
              // arrange elements so that they always reach the right border
              let end = positions.length
              let start = end
              while (start > 0 && positions[start - 1].row == row) start--
              let rowWidth = 0
              for (let i = start; i < end; i++) {
                rowWidth += positions[i].width
                rowWidth -= tabOverlapDistance
              }
              rowWidth += tabOverlapDistance
              let rowScale = tabsContentWidth / rowWidth
              let rowLeft = 0
              for (let i = start; i < end; i++) {
                let pos = positions[i]
                pos.left = rowLeft
                pos.width = Math.round((pos.width - tabOverlapDistance) * rowScale) + tabOverlapDistance
                rowLeft = pos.left + pos.width - tabOverlapDistance
              }
              if (end > start) {
                let pos = positions[end - 1]
                pos.width = tabsContentWidth - pos.left
              }
            }
          }
          left = 0
          top += tabHeight
          row += 1
          column = 0
          
          if (tabsPerRow > maxTabsPerRow) maxTabsPerRow = tabsPerRow
          tabsPerRow = 0
          
          let systemButtons
          if (row == 1 && this.options.flowAroundSystemButtons && (systemButtons = this.el.querySelector(".system-buttons"))) {
            overflow = true
            tabsContentWidth += systemButtons.offsetWidth;
          }
        } else { // not linebreak
          tabsPerRow += 1
        }
        positions.push({ tabEl, left, top, row, column, width })
        left += width - tabOverlapDistance
        column += 1
      }
      
      // todo: maybe a clipping mask? Tabs must not overflow the buttons on the right if available
      this.tabContentEl.style.overflow = overflow ? "initial" : "hidden";
      
      if (tabEls.length > 0) {
        document.documentElement.style.setProperty("--chrome-tabs-height", (top + tabHeight) + "px")
      } else document.documentElement.style.removeProperty("--chrome-tabs-height")
      if (setDatasetValue(document.documentElement, "multilineTabs", top > 0 ? "" : null)) {
        var _ignore = this.ignoreResize;
        this.ignoreResize = true;
        var e = new CustomEvent("resize");
        e.initEvent("resize");
        window.dispatchEvent(e);
        this.ignoreResize = _ignore;
      }
      setTokenFlag(this.el.classList, "chrome-tabs-boxy", top > 0 || this.options.boxyTabs);
      if (tabsPerRow > maxTabsPerRow) maxTabsPerRow = tabsPerRow
      positions.tabsPerRow = maxTabsPerRow
      positions.tabRows = row + 1
      return positions
    }

    layoutTabs() {
      const tabWidth = this.tabWidth

      this.cleanUpPreviouslyDraggedTabs()
      if (!(this.options.multiline && this.options.fitText)) {
        this.tabEls.forEach((tabEl) => tabEl.style.width = tabWidth + 'px')
      }
      requestAnimationFrame(() => {
        let styleHTML = ''
        // +y: round x
        this.tabPositions.forEach((pos, i) => {
          pos.tabEl.style.width = pos.width + "px"
          styleHTML += `
            .chrome-tabs[data-chrome-tabs-instance-id="${ this.instanceId }"] .chrome-tab:nth-child(${ i + 1 }) {
              transform: translate3d(${ pos.left|0 }px, ${ pos.top|0 }px, 0)
            }
          `
        })
        this.animationStyleEl.innerHTML = styleHTML
      })
    }

    fixZIndexes() {
      const bottomBarEl = this.el.querySelector('.chrome-tabs-bottom-bar')
      const tabEls = this.tabEls
      const tabPositions = this.tabPositions
      const tabsPerRow = tabPositions.tabsPerRow
      const tabRows = tabPositions.tabRows

      tabEls.forEach((tabEl, i) => {
        let tabPos = tabPositions[i]
        let zIndexBase = (tabRows - 1 - tabPos.row) * tabsPerRow
        let zIndex = zIndexBase + tabsPerRow - tabPos.column

        if (tabEl.classList.contains('chrome-tab-current')) {
          bottomBarEl.style.zIndex = zIndexBase + tabsPerRow + 1
          zIndex = zIndexBase + tabsPerRow + 2
        }
        tabEl.style.zIndex = zIndex
      })
    }

    createNewTabEl() {
      const div = document.createElement('div')
      div.innerHTML = tabTemplate
      return div.firstElementChild
    }

    addTab(tabProperties) {
      const tabEl = this.createNewTabEl()

      tabEl.classList.add('chrome-tab-just-added')
      setTimeout(() => tabEl.classList.remove('chrome-tab-just-added'), 500)

      tabProperties = Object.assign({}, defaultTapProperties, tabProperties)
      this.tabContentEl.appendChild(tabEl)
      this.updateTab(tabEl, tabProperties)
      this.emit('tabAdd', { tabEl })
      this.setCurrentTab(tabEl)
      this.layoutTabs()
      this.fixZIndexes()
      this.setupDraggabilly()
    }

    setCurrentTab(tabEl) {
      const currentTab = this.el.querySelector('.chrome-tab-current')
      if (currentTab) currentTab.classList.remove('chrome-tab-current')
      tabEl.classList.add('chrome-tab-current')
      this.fixZIndexes()
      this.emit('activeTabChange', { tabEl })
    }

    removeTab(tabEl) {
      /*if (tabEl.classList.contains('chrome-tab-current')) {
        if (tabEl.previousElementSibling) {
          this.setCurrentTab(tabEl.previousElementSibling)
        } else if (tabEl.nextElementSibling) {
          this.setCurrentTab(tabEl.nextElementSibling)
        }
      }*/ // +y: handled on Haxe side instead
      let prevTab = tabEl.previousElementSibling
      let nextTab = tabEl.nextElementSibling
      tabEl.parentNode.removeChild(tabEl)
      this.emit('tabRemove', { tabEl, prevTab, nextTab })
      this.layoutTabs()
      this.fixZIndexes()
      this.setupDraggabilly()
    }

    updateTab(tabEl, tabProperties) {
      tabEl.querySelector('.chrome-tab-title-text').textContent = tabProperties.title
      tabEl.querySelector('.chrome-tab-favicon').style.backgroundImage = `url('${tabProperties.favicon}')`
    }

    cleanUpPreviouslyDraggedTabs() {
      this.tabEls.forEach((tabEl) => tabEl.classList.remove('chrome-tab-just-dragged'))
    }
    
    simpleDragTab = null
    simpleDragSetEvents(tabEl, enable) {
      if (!!tabEl.chromeTabsSimpleDrag == enable) return
      
      let events = this.simpleDragEvents
      if (events == null) {
        events = {
          'dragstart': (e) => {
            let el = e.target
            let dt = e.dataTransfer
            this.simpleDragTab = el
            el.classList.add("chrome-tab-simple-drag")
            dt.setData('text/plain',el.querySelector('.chrome-tab-title').innerText)
            dt.setData('application/gmedit-tab-url',el.dataset.context)
            dt.effectAllowed = "move"
          },
          'dragover': (e) => {
            if (e.dataTransfer.types.includes('application/gmedit-tab-url')) e.preventDefault()
          },
          'dragenter': (e) => {
            if (e.target.classList.contains('chrome-tab')) e.target.classList.add('chrome-tab-simple-drop')
          },
          'dragleave': (e) => {
            if (e.target.classList.contains('chrome-tab')) e.target.classList.remove('chrome-tab-simple-drop')
          },
          'drop': (e) => {
            e.preventDefault()
            
            let source = this.simpleDragTab
            if (!source) return
            source.classList.remove('chrome-tab-simple-drag')
            
            let target = e.target
            if (!target.classList.contains('chrome-tab')) return
            target.classList.remove('chrome-tab-simple-drop')
            
            if (source.parentElement != target.parentElement) return
            
            if (source.nextElementSibling == target) {
              let t = target
              target = source
              source = t
            }
            
            // when dropping the tab to another row, update its pinned status accordingly
            this.setTabPinLayer(source, this.getTabPinLayer(target))
            
            source.parentElement.insertBefore(source, target)
            this.simpleDragTab = null
            this.layoutTabs()
            GMEdit._emit("tabsReorder", {target:this})
          },
        }
        for (let prop in events) events[prop] = events[prop].bind(this)
        this.simpleDragEvents = events;
      }
      
      tabEl.chromeTabsSimpleDrag = enable
      tabEl.draggable = enable
      for (let prop in events) {
        if (enable) {
          tabEl.addEventListener(prop, events[prop])
        } else {
          tabEl.removeEventListener(prop, events[prop])
        }
      }
    }

    setupDraggabilly() {
      const tabEls = this.tabEls
      const tabEffectiveWidth = this.tabEffectiveWidth
      const tabPositions = this.tabPositions

      this.draggabillyInstances.forEach(draggabillyInstance => draggabillyInstance.destroy())
      
      if (this.options.multiline || this.options.fitText) {
        for (let tabEl of tabEls) this.simpleDragSetEvents(tabEl, true)
        return
      } else {
        for (let tabEl of tabEls) this.simpleDragSetEvents(tabEl, false)
      }

      tabEls.forEach((tabEl, originalIndex) => {
        const originalTabPositionX = tabPositions[originalIndex].left
        const draggabillyInstance = new Draggabilly(tabEl, {
          axis: 'x',
          containment: this.tabContentEl
        })

        this.draggabillyInstances.push(draggabillyInstance)

        draggabillyInstance.on('dragStart', () => {
          this.cleanUpPreviouslyDraggedTabs()
          tabEl.classList.add('chrome-tab-currently-dragged')
          this.el.classList.add('chrome-tabs-sorting')
          this.fixZIndexes()
        })

        draggabillyInstance.on('dragEnd', () => {
          const finalTranslateX = parseFloat(tabEl.style.left, 10)
          tabEl.style.transform = `translate3d(0, 0, 0)`

          // Animate dragged tab back into its place
          requestAnimationFrame(() => {
            tabEl.style.left = '0'
            tabEl.style.transform = `translate3d(${ finalTranslateX }px, 0, 0)`

            requestAnimationFrame(() => {
              tabEl.classList.remove('chrome-tab-currently-dragged')
              this.el.classList.remove('chrome-tabs-sorting')

              this.setCurrentTab(tabEl)
              tabEl.classList.add('chrome-tab-just-dragged')

              requestAnimationFrame(() => {
                tabEl.style.transform = ''

                this.setupDraggabilly()
                GMEdit._emit("tabsReorder", {target:this})
              })
            })
          })
        })

        draggabillyInstance.on('dragMove', (event, pointer, moveVector) => {
          // Current index be computed within the event since it can change during the dragMove
          const tabEls = this.tabEls
          const currentIndex = tabEls.indexOf(tabEl)

          const currentTabPositionX = originalTabPositionX + moveVector.x
          const destinationIndex = Math.max(0, Math.min(tabEls.length, Math.floor((currentTabPositionX + (tabEffectiveWidth / 2)) / tabEffectiveWidth)))

          if (currentIndex !== destinationIndex) {
            this.animateTabMove(tabEl, currentIndex, destinationIndex)
          }
        })
      })
    }

    animateTabMove(tabEl, originIndex, destinationIndex) {
      if (destinationIndex < originIndex) {
        tabEl.parentNode.insertBefore(tabEl, this.tabEls[destinationIndex])
      } else {
        tabEl.parentNode.insertBefore(tabEl, this.tabEls[destinationIndex + 1])
      }
    }
  }

  if (isNodeContext) {
    module.exports = ChromeTabs
  } else {
    window.ChromeTabs = ChromeTabs
  }
})()
