/**
 * An Ace-editor-provided list of language tokens 
 * @typedef {Object} Token
 * @prop {string} type - Indicates the token type
 * @prop {string} value - The value of the current token
 */

 /**
 * Optional configuration for GML reconstruction
 * @typedef {Object} Configuration
 * @prop {string} [indentation] - Represents the string to use as the base indentation character, four spaces by default
 */

/**
 * Reconstructs GML based on an input array of tokens
 * @param {Array<Token>} tokenInput - Valid ace-defined tokens array
 * @param {Configuration} [options] - Formatting options
 */
function formatGML(tokenInput, options) {

  // Default options
  options = options ? options : {};
  options.indentation = options.indentation || '    ';

  /** Contains reconstructed GML */
  let output = '';

  /** Represents the current indentation level */
  let indentation = 0;

  let currentIndentation = '';

  let inFor = false;

  let prevChar = '';

  let fixedInput = [];
  tokenInput.forEach(token => {
    token.value = token.type.indexOf('comment') !== -1 ? token.value : token.value.trim();
    if (token.value.length !== 0) fixedInput.push(token);
  });
  tokenInput = fixedInput;

  // Loop through each token
  tokenInput.forEach((token, index) => {
    prevChar = '';

    currentIndentation = options.indentation.repeat(indentation);

    let nextToken = null;
    if (index + 1 < tokenInput.length) {
      nextToken = tokenInput[index + 1];
    }

    let previousToken = null;
    if (index - 1 > 0) {
      previousToken = tokenInput[index - 1];
    }

    // Handle each token on a type basis
    switch (token.type) {
      case 'comment.doc.line':
        output += token.value;
        break;
      case 'comment':
        output += '\n' + currentIndentation;
      case 'comment.line':
        output += token.value + '\n' + currentIndentation;
        break;
      case 'keyword':
        if (previousToken !== null && previousToken.type.indexOf('comment') === -1 && previousToken.type !== 'keyword' && token.value !== 'then' && token.value !== 'else') {
          output += '\n' + currentIndentation;
        }

        if (token.value === 'then' || token.value === 'else') {
          if (token.value === 'else' && previousToken !== null && previousToken.type === 'curly.paren.rparen') {
            output = output.substring(0, output.length - 1);
          }

          output += ' ';
        }

        output += `${token.value} `;
        if (token.value === 'for') inFor = true;
        break;
      case 'operator':
      case 'set.operator':
        if (token.value === '!') {
          output += token.value;
        } else {
          output += ` ${token.value}`;

          if (nextToken !== null) {
            if (nextToken.type !== 'paren.rparen') output += ' ';
          }
        }

        break;
      case 'punctuation.operator':
        output += readPuncOperator(token.value);
        break;
      case 'curly.paren.lparen':
        inFor = false;
        indentation++;
        currentIndentation = options.indentation.repeat(indentation);

        prevChar = output.substring(output.length - 1);

        if (prevChar !== ' ') output += ' ';

        output += `${token.value + '\n' + currentIndentation}`;
        break;
      case 'curly.paren.rparen':
        indentation--;
        currentIndentation = options.indentation.repeat(indentation);

        prevChar = output.substring(output.length - 1);

        if (prevChar !== '\n' && previousToken !== null && previousToken.type !== 'curly.paren.rparen' && previousToken.value !== ';') {
          output += '\n' + currentIndentation;
        } else {
          output = output.substring(0, output.length - options.indentation.length);          
        }

        output += token.value + '\n' + currentIndentation;
        break;
      default:
        output += token.value;
        if (token.value === '|') output += ' ';
        break;
    }
  });

  /**
   * @param {string} operator
   */
  function readPuncOperator(operator) {
    switch (operator) {
      case ';':
        return operator + (inFor ? ' ' : '\n' + currentIndentation);
        break;
      default:
        return operator + ' ';
        break;
    }
  }

  return output;
}

/**
 * @returns {Array<Token>}
 */
function tokenizeAceContents() {
  let list = [];
  let TokenIterator = ace.require('ace/token_iterator').TokenIterator;
  let iter = new TokenIterator(aceEditor.session, 0, 0);
  let tk = iter.getCurrentToken();
  while (tk != null) {
    list.push(tk);
    tk = iter.stepForward();
  }
  return list;
}

/**
 * Formats the GML contents of the current Ace editor
 */
function formatAceGMLContents() {
  if (aceEditor.getSession().getMode().$id !== 'ace/mode/gml') return;
  let tokenList = tokenizeAceContents();
  let prettyGML = formatGML(tokenList);
  aceEditor.setValue(prettyGML);
  aceEditor.selection.clearSelection();
}
