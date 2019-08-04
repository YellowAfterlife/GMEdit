/**
 * This class allows reading the Windows accent colors from the registry.
 * Works in Windows 10 and above (7 and 8 not tested yet)
 */
class WindowsAccentColors {
  constructor () {
    this.checkSupport()

    if (this.isSupported) {
      this.reload()
    }
  }

  /**
   * Checks for the OS and release and sets corresponding variables
   * @return {void}
   */
  checkSupport () {
    const os = require('os')
    this.isWin = os.platform() === 'win32'
    this.isWin10 = this.isWin && parseInt(os.release()) === 10
    this.isWin8 = this.isWin && [6.2, 6.3].indexOf(parseFloat(os.release())) !== -1
    this.isWin7 = this.isWin && parseFloat(os.release()) === 6.1

    this.isSupported = this.isWin7 || this.isWin8 || this.isWin10
  }

  /**
   * Rewrites a registry hex value to a hex color string. Ignores alpha channel.
   * @param  {string} hex The hex value from the registry
   * @return {string} A hex color string in #rrggbb format
   */
  hex2color (hex) {
    return '#' +
      '0'.repeat(Math.max(0, 8 - hex.length)) +
      hex.substr(2 + Math.max(0, hex.length - 8))
  }

  /**
   * Parses a registry hex value to a boolean.
   * @param  {string} hex The hex value from the registry
   * @return {boolean} The converted boolean
   */
  hex2bool (hex) {
    return hex !== '0x0'
  }
  
  /**
   * Returns the expected text color for the given background color.
   * @param {string} color A hex color string in #rrggbb format
   * @return {string} A hex color string in #rrggbb format
   */
  textColor (color) {
    return (parseInt(color.substr(1, 2), 16) * 2 +
      parseInt(color.substr(3, 2), 16) * 5 +
      parseInt(color.substr(5, 2), 16)
    ) <= (8 * 128) ? "#ffffff" : "#000000"
  }

  /**
   * Reloads the accent color configuration from the registry
   * @return {void}
   */
  reload () {
    const os = require('os')
    this.accentData = require('child_process')
      .execSync('REG QUERY HKCU\\SOFTWARE\\Microsoft\\Windows\\DWM')
      .toString('utf-8')
      .trim()
      .split(os.EOL)
      .slice(1)
      .reduce((carry, row) => {
        const rowData = row.trim().split('    ')
        return Object.assign({}, carry, {
          [rowData[0]]: rowData[2]
        })
      }, {})

    // The keys that should be handled as booleans
    const booleans = [
      'Composition',
      'ColorizationBlurBalance',
      'ColorizationGlassAttribute',
      'ColorizationOpaqueBlend',
      'EnableAeroPeek',
      'ColorPrevalence',
      'EnableWindowColorization'
    ]

    // We'll just handle everything unknown as a color
    Object.keys(this.accentData).forEach(key => {
      if (booleans.indexOf(key) !== -1) {
        this.accentData[key] = this.hex2bool(this.accentData[key])
      } else {
        this.accentData[key] = this.hex2color(this.accentData[key])
      }
    })

    if (this.isWin7) {
      this.isDetectable = this.accentData.Composition === true && this.accentData.ColorizationOpaqueBlend === false
    } else {
      this.isDetectable = this.isSupported
    }
  }

  /**
   * Gets the parsed registry items
   * @return {Object} An object with the item names as keys and hex color strings/booleans as values
   */
  get raw () {
    return this.accentData
  }

  /**
   * Gets the titlebar's color
   * @return {string} The hex code of the title bar color
   */
  get titlebarColor () {
    if (this.isWin10) {
      return this.raw.ColorPrevalence ? this.raw.ColorizationColor : '#ffffff'
    } else {
      return this.raw.ColorizationColor
    }
  }
  
  get titlebarTextColor () {
    return this.textColor(this.titlebarColor)
  }

  /**
   * Gets the inactive titlebar's color
   * @return {string} The hex code of the title bar color when it's inactive
   */
  get inactiveTitlebarColor () {
    if (this.isWin10) {
      // Inactive window color is interchangeable in Win10 by addinc the 'AccentColorInactive' entry
      return this.raw.AccentColorInactive != null ? this.raw.AccentColorInactive : '#ffffff'
    } else {
      return '#ebebeb'
    }
  }
  
  get inactiveTitlebarTextColor () {
    return this.textColor(this.inactiveTitlebarColor)
  }
}

module.exports = new WindowsAccentColors()
