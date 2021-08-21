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
            <symbol id="topright" viewBox="0 0 214 29">
              <use xlink:href="#topleft"/>
            </symbol>
            <clipPath id="crop">
              <rect class="mask" width="100%" height="100%" x="0"/>
            </clipPath>
          </defs>
          <svg width="51%" height="100%" transfrom="scale(-1, 1)">
            <use xlink:href="#topleft" width="214" height="29" class="chrome-tab-background"/>
            <use xlink:href="#topleft" width="214" height="29" class="chrome-tab-shadow"/>
          </svg>
          <g transform="scale(-1, 1)"><svg width="50%" height="100%" x="-100%" y="0">
            <use xlink:href="#topright" width="214" height="29" class="chrome-tab-background"/>
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

    setupEvents() {
      window.addEventListener('resize', event => {
        if (!this.ignoreResize) this.layoutTabs()
      })

      //this.el.addEventListener('dblclick', event => this.addTab())
      this.el.addEventListener('mouseup', ({which, target}) => {
        if (which != 2) return;
        let tcl = target.classList;
        if (tcl.contains('chrome-tab') || tcl.contains('chrome-tab-close') || tcl.contains('chrome-tab-title') || tcl.contains('chrome-tab-title-text') || tcl.contains('chrome-tab-favicon')) {
          let tab = tcl.contains('chrome-tab') ? target : target.parentElement;
          if (tcl.contains('chrome-tab-title-text')) tab = tab.parentElement;
          if (tab) tab.querySelector('.chrome-tab-close').click();
        }
      })

      this.el.addEventListener('click', (e) => {
        let target = e.target
        if (target.classList.contains('chrome-tab')) {
          if (e.ctrlKey) {
            if (target.classList.toggle("chrome-tab-pinned")) {
              for (let tabEl of this.tabEls) {
                if (!tabEl.classList.contains("chrome-tab-pinned")) {
                  tabEl.before(target)
                  break
                }
              }
            } else {
              let lastPinned = null
              for (let tabEl of this.tabEls) {
                if (tabEl.classList.contains("chrome-tab-pinned")) {
                  lastPinned = tabEl
                }
              }
              if (lastPinned) lastPinned.after(target)
            }
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
      const tabHeight = tabEls[0]?.offsetHeight ?? 28
      const multiline = this.options.multiline
      const fitText = multiline && this.options.fitText
      const tabOverlapDistance = this.options.tabOverlapDistance
      let left = 0, top = 0
      let row = 0, column = 0
      let tabsPerRow = 0
      let positions = []
      let overflow = false
      //console.log(tabEffectiveWidth, tabsContentWidth)
      
      tabEls.forEach((tabEl, i) => {
        //console.log({ i, row, column, left, top, right: left + tabEffectiveWidth })
        let width
        if (fitText) {
          let titleText = (tabEl.querySelector('.chrome-tab-title-text')?.offsetWidth
            ?? tabEl.querySelector('.chrome-tab-title').offsetWidth // compatibility with plugins that overwrite title-text
          )
          width = titleText.offsetWidth + 49 + tabOverlapDistance
          width = Math.min(width, tabsContentWidth)
        } else width = tabWidth
        if (multiline && left + width > tabsContentWidth) {
          if (fitText) {
            // arrange elements so that they always reach the right border
            let end = positions.length
            let start = end
            while (start > 0 && positions[start - 1].row == row) start--
            let rowWidth = 0
            for (let i = start; i < end; i++) {
              rowWidth += positions[i].width - tabOverlapDistance
            }
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
          left = 0
          top += tabHeight
          row += 1
          column = 0
          let systemButtons
          if (row == 1 && this.options.flowAroundSystemButtons && (systemButtons = this.el.querySelector(".system-buttons"))) {
            overflow = true
            tabsContentWidth += systemButtons.offsetWidth;
          }
        } else if (row == 0) {
          tabsPerRow += 1
        }
        positions.push({ tabEl, left, top, row, column, width })
        left += width - tabOverlapDistance
        column += 1
      })
      
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
      setDatasetValue(document.documentElement, "boxyTabs", top > 0 || this.options.boxyTabs ? "" : null)
      positions.tabsPerRow = tabsPerRow
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

    setupDraggabilly() {
      const tabEls = this.tabEls
      const tabEffectiveWidth = this.tabEffectiveWidth
      const tabPositions = this.tabPositions

      this.draggabillyInstances.forEach(draggabillyInstance => draggabillyInstance.destroy())

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
