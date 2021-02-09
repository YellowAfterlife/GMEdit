const fontManager = require(`./fontmanager-${process.platform}-${process.arch}.node`);

module.exports = {
  findFontSync: (fontDescriptor) => fontManager.findFontSync(fontDescriptor),
  findFont: (fontDescriptor) => new Promise(
    (resolve, reject) => {
      try {
        fontManager.findFont(
          fontDescriptor,
          (error, font) => error !== null
            ? reject(error)
            : resolve(font)
        );
      } catch (error) {
        reject(error);
      }
    }
  ),
  findFontsSync: (fontDescriptor) => fontManager.findFontsSync(fontDescriptor),
  findFonts: (fontDescriptor) => new Promise(
    (resolve, reject) => {
      try {
        fontManager.findFonts(
          fontDescriptor,
          (error, fonts) => error !== null
          ? reject(error)
          : resolve(fonts)
        );
      } catch (error) {
        reject(error);
      }
    }
  ),
  getAvailableFontsSync: () => fontManager.getAvailableFontsSync(),
  getAvailableFonts: () => new Promise(
    (resolve, reject) => {
      try {
        fontManager.getAvailableFonts(
          (error, fonts) => error !== null
            ? reject(error)
            : resolve(fonts)
        );
      } catch (error) {
        reject(error);
      }
    }
  ),
  substituteFontSync: (postscriptName, text) => fontManager.substituteFontSync(postscriptName, text),
  substituteFont: (postscriptName, text) => new Promise(
    (resolve, reject) => {
      try {
        fontManager.substituteFont(
          postscriptName,
          text,
          (error, font) => error !== null
            ? reject(error)
            : resolve(font)
        );
      } catch (error) {
        reject(error);
      }
    }
  )
};
