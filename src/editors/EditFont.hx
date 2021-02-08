package editors;

import electron.FileSystem;
import haxe.io.Path;
import gml.GmlVersion;
import js.lib.Math;
import js.lib.Intl;
import tools.JsTools;
import js.lib.RegExp;
import tools.NativeString;
import gml.Project;
import yy.YyJson;
import electron.Dialog;
import yy.YyFont;
import tools.Dictionary;
import js.html.*;
import electron.FontScanner;
import electron.FileWrap;
import file.kind.yy.KYyFont;
import gml.file.GmlFile;
import Main.document;
using tools.HtmlTools;
using Lambda;

class EditFont extends Editor {
	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		element.id = "font-editor";
		fontFamilies = new Dictionary();
	}

	private var font: YyFont;

	private var imageFileExists: Bool = false;
	private var needsRegenerationWarning: ParagraphElement;

	private var fontFamilies: Dictionary<FontFamily>;
	private var fontFamilySelect: SelectElement;
	private var fontStyleSelect: SelectElement;
	private var fontSizeInput: InputElement;
	private var previewTextArea: TextAreaElement;
	private var rangeWindow: DivElement;
	private var moreRangeOptionsDiv: DivElement;
	private var rangesDiv : DivElement;

	public override function load(data:Dynamic) {
		super.load(data);


		if (Std.is(file.kind, KYyFont) == false) {
			return;
		}

		if (data == null) data = FileWrap.readYyFileSync(file.path);
		if (data == null) {
			return;
		}
		font = data;

		var imagePath = getImageFileName();
		imageFileExists = FileSystem.existsSync(imagePath);

		buildPage();

		FontScanner.getAvailableFonts().then(onFontsLoaded);
	}

	private function getImageFileName() {
		var directory = Path.directory(file.path);
		return Path.join([directory, font.name]) + ".png";
	}

	public override function save(): Bool {
		var newFontJson = YyJson.stringify(font, Project.current.yyExtJson);
		file.writeContent(newFontJson);
		file.changed = false;

		// Remove the old .png if it exists
		var directory = Path.directory(file.path);
		var imagePath = getImageFileName();
		if (FileSystem.existsSync(imagePath)) {
			imageFileExists = false;
			FileSystem.renameSync(imagePath, Path.join([directory, font.name]) + ".old.png");
		}

		return true;
	}

	private function onFontsLoaded(fonts: Array<FontDescriptor>) {
		processFonts(fonts);

		fontFamilySelect.clearInner();

		var fontList = fontFamilies.keys();
		fontList.sort((a, b) -> a < b ? -1 : 1);

		for (fontName in fontList) {
			var optionElement = document.createOptionElement();
			optionElement.innerText = fontName;
			fontFamilySelect.appendChild(optionElement);
			// Set the current family as the marked one
			if (font.fontName == fontName) {
				optionElement.selected = true;
			}
		}

		populateStyles();
		updatePreview();
	}

	/** Puts fonts in the proper family*/
	private function processFonts(fonts: Array<FontDescriptor>) {
		fontFamilies.clear();
		
		for (font in fonts) {
			if (fontFamilies.exists(font.family) == false) {
				fontFamilies[font.family] = {name: font.family, children: new Array()};
			}
			fontFamilies[font.family].children.push(font);
		}

		// Sort children alphabetically
		for (familyName in fontFamilies.keys()) {
			fontFamilies[familyName].children.sort((a, b) -> a.style < b.style ? -1 : 1);
		}
	}

	/**Returns the current font descriptor*/
	private function getCurrentFont():FontDescriptor {
		var family = fontFamilies[font.fontName];
		if (family == null) {
			return null;
		}
		for (child in family.children) {
			if (child.style == font.styleName) {
				return child;
			}
		}
		return null;
	}

	private function onFamilyChanged() {
		var newName = (cast fontFamilySelect.options[fontFamilySelect.selectedIndex]).text;
		if (newName == font.fontName || newName == "" || newName == null) {
			return;
		}
		
		if (fontFamilies.exists(newName) == false) {
			Dialog.showAlert("Failed to load font " + newName);
			return;
		}
		
		font.fontName = newName;
		var family = fontFamilies[newName];

		// This code will prioritize the style name in the following order:
		// 1: Matching old, 2: Regular, 3: First in the list
		var oldStyleName = font.styleName;
		font.styleName = family.children[0].style;
		for (familyChild in family.children) {
			if (familyChild.style == oldStyleName) {
				font.styleName = familyChild.style;
				break;
			}
			if (familyChild.style == "Regular") {
				font.styleName = familyChild.style;
			}
		}

		populateStyles();
		onFontChanged();
	}

	private function onStyleChanged() {
		var newStyle = (cast fontStyleSelect.options[fontStyleSelect.selectedIndex]).text;
		if (newStyle == font.styleName || newStyle == "" || newStyle == null) {
			return;
		}

		font.styleName = newStyle;
		onFontChanged();
	}

	private function onSizeChanged() {
		var newSize = Std.parseFloat(fontSizeInput.value);
		if (newSize == font.size || newSize == Math.NaN) {
			return;
		}

		font.size = newSize;
		onFontChanged();
	}

	/**Fills the style selector with styles of the current font*/
	private function populateStyles() {
		fontStyleSelect.clearInner();

		var currentFontFamily = fontFamilies[font.fontName];
		if (currentFontFamily != null) {
			for (fontChild in currentFontFamily.children) {
				var optionElement = document.createOptionElement();
				optionElement.innerText = fontChild.style;
				fontStyleSelect.appendChild(optionElement);
				// Set the current style as the marked one
				if (font.styleName == fontChild.style) {
					optionElement.selected = true;
				}
			}
		} else {
			{
				var currentSelectOption = document.createOptionElement();
				currentSelectOption.innerText = font.styleName;
				fontStyleSelect.appendChild(currentSelectOption);
				currentSelectOption.selected = true;
			}

			{
				var loadingSelectOption = document.createOptionElement();
				loadingSelectOption.innerText = "Could not find more styles";
				fontStyleSelect.appendChild(loadingSelectOption);
			}
		}
	}

	function addRangeElement(range: YyFontRange): DivElement {
		rangesDiv = document.createDivElement();
		rangesDiv.classList.add("font-range");

		{
			var rangeInput = document.createInputElement();
			if (range.lower == range.upper) {
				rangeInput.value = '${range.lower}';
			} else {
				rangeInput.value = '${range.lower}-${range.upper}';
			}
		
			rangeInput.addEventListener("input", () -> onRangeChanged(rangeInput, range));
			rangeInput.addEventListener("blur", () -> onRangeUnfocus(rangeInput, range));
			rangeInput.addEventListener("keyup", function(event:KeyboardEvent) {
				if (event.keyCode == 13) {
					event.preventDefault();
					onRangeUnfocus(rangeInput, range);
				}
			});
			rangesDiv.appendChild(rangeInput);
		}

		// Can't remove what's already gone *taps forehead*
		{
			var closeButton = document.createButtonElement();
			closeButton.innerHTML = "x";
			closeButton.title = "Remove range";
			closeButton.addEventListener("click", function() {
				font.ranges.remove(range);
				rangesDiv.remove();
				onFontChanged();
			});
			rangesDiv.appendChild(closeButton);
		}

		return rangesDiv;
	}

	private function populateRanges() {
		rangeWindow.clearInner();

		for (range in font.ranges) {
			var rangeDiv = addRangeElement(range);
			rangeWindow.appendChild(rangeDiv);
		}

	}

	private function getRangeValues(input: String): Array<Int> {
		var ranges = input.split('-').filter(x -> x != "");

		if (ranges.length == 0) {
			return [];
		}

		var intRanges:Array<Int> = ranges.map(x -> Std.parseInt(x)).map(x -> Math.max(x, 32));

		if (intRanges.length == 0) {
			return [];
		}

		intRanges.sort((a, b) -> a-b);
		if (intRanges.length == 1) {
			return [intRanges[0], intRanges[0]];
		}
		return intRanges.slice(0, 2);
	}

	private function onRangeChanged(element: InputElement, range: YyFontRange) {
		element.value = NativeString.replaceExt(element.value, JsTools.rx(~/[^0-9\\-]/gi), '');
		var intRanges = getRangeValues(element.value);

		// Don't do auto updates if value is larger than 1000
		if (intRanges[1] - intRanges[0] > 1000) {
			return;
		}

		// Temporairly update the range for preview purposes
		var oldLower = range.lower;
		var oldUpper = range.upper;
		range.lower = intRanges[0];
		range.upper = intRanges[1];
		onFontChanged();
		// Set the range back so we dont potentially leave it in a broken state
		range.lower = oldLower;
		range.upper = oldUpper;
	}
	private function onRangeUnfocus(element: InputElement, range: YyFontRange) {
		var result = element.value;
		
		var intRanges = getRangeValues(result);
		if (intRanges.length == 0) {
			element.parentElement.remove();
			font.ranges.remove(range);
			onFontChanged();
			return;
		}

		// Remove old range and insert new range
		// This ensures it's properly sorted and merged as necessary
		font.ranges.remove(range);
		font.addRange({lower: intRanges[0], upper: intRanges[1]});
		populateRanges();
		onFontChanged();
	}
	
	private function onFontChanged(refreshPreview: Bool = true) {
		var fontDescriptor = getCurrentFont();
		if (fontDescriptor != null) {
			font.italic = fontDescriptor.italic;
		}
		// This looks hella weird because it is, but from my limited testing it seems to be how GM determines if it's a bold or not font as well
		font.bold = font.styleName.toLowerCase().indexOf("bold") >= 0;

		file.changed = true;
		if (refreshPreview) {
			updatePreview();
		}
	}

	var lastPreviewText:String = null;
	private function onPreviewTextChanged() {
		if (previewIsGettingSet) {
			return;
		}
		if (lastPreviewText == previewTextArea.value) {
			return;
		}
		if (previewTextArea.disabled) {
			return;
		}

		font.ranges = [];
		font.addCharacters(previewTextArea.value);
		lastPreviewText = previewTextArea.value;
		populateRanges();
		onFontChanged(false);
	}

	private function onPreviewTextLostFocus() {
		var text = previewTextArea.value;
		var charcodeArray = new Array<Int>();

		for (letter in StringTools.iterator(text)) {
			charcodeArray.push(letter);
		}

		charcodeArray.sort((a, b) -> a-b);
		var last = -1;
		var str = "";
		for (charCode in charcodeArray) {
			if (last == charCode) {
				continue;
			}
			last = charCode;
			str+=String.fromCharCode(charCode);
		}

		previewTextArea.value = str;
	}

	/**Used to prevent a feedback loop where updating a value in preview triggers an event back and forth*/
	var previewIsGettingSet = false;
	/**Updates the size and font inside the preview-window*/
	private function updatePreview() {
		var fontDescriptor = getCurrentFont();
		previewIsGettingSet = true;
		
		if (fontDescriptor != null) {
			previewTextArea.style.fontWeight = Std.string(fontDescriptor.weight);
			previewTextArea.style.fontFamily = '"${fontDescriptor.postscriptName}", "${fontDescriptor.family} ${fontDescriptor.style}", "${fontDescriptor.family}"';
		} else {
			previewTextArea.style.fontWeight = "normal";
			previewTextArea.style.fontFamily = '"${font.fontName} ${font.styleName}", "${font.fontName}"';
		}

		previewTextArea.style.fontStyle = font.italic ? "italic" : "normal";
		previewTextArea.style.fontSize = Std.string(font.size) + "pt";


		if (font.characterCount > 5000) {
			previewTextArea.disabled = true;
			previewTextArea.value = "There's too many characters to preview\nHere's some preview text:\n\n" + font.sampleText;
		}
		else {
			lastPreviewText = font.getAllCharacters();
			previewTextArea.disabled = false;
			previewTextArea.value = lastPreviewText;
		}
		previewIsGettingSet = false;
	}

	private function onImagefileChanged() {
		needsRegenerationWarning.style.display = imageFileExists ? "none" : "unset";
	}

	// Sneakily put at the bottom so you never have to see it
	/**Builds the HTML page*/
	private function buildPage() {
		var header = document.createElement("h2");
		header.innerHTML = file.name;
		element.appendChild(header);

		var container = document.createDivElement();


		{
			var optionsDiv = document.createDivElement();
			optionsDiv.id = "font-options";

			function addOptionElement(name: String, element: Element) {
				var headerDiv = document.createDivElement();
				var paragraph = document.createParagraphElement();
				paragraph.innerHTML = name;
				headerDiv.appendChild(paragraph);
				headerDiv.appendChild(element);
				headerDiv.classList.add("option");
				
				optionsDiv.append(headerDiv);
			}

			// Font family selector
			{
				fontFamilySelect = document.createSelectElement();
				{
					var currentSelectOption = document.createOptionElement();
					currentSelectOption.innerText = font.fontName;
					fontFamilySelect.appendChild(currentSelectOption);
					currentSelectOption.selected = true;
				}

				{
					var loadingSelectOption = document.createOptionElement();
					loadingSelectOption.innerText = "Loading more fonts...";
					fontFamilySelect.appendChild(loadingSelectOption);
				}

				fontFamilySelect.addEventListener("change", onFamilyChanged);
				addOptionElement("Font family", fontFamilySelect);
			}

			// Font type selector
			{
				fontStyleSelect = document.createSelectElement();
				{
					var currentSelectOption = document.createOptionElement();
					currentSelectOption.innerText = font.styleName;
					fontStyleSelect.appendChild(currentSelectOption);
					currentSelectOption.selected = true;
				}

				{
					var loadingSelectOption = document.createOptionElement();
					loadingSelectOption.innerText = "Loading more styles...";
					fontStyleSelect.appendChild(loadingSelectOption);
				}
				fontStyleSelect.addEventListener("change", onStyleChanged);
				addOptionElement("Font style", fontStyleSelect);
			}

			// Font size selection
			{
				fontSizeInput = document.createInputElement();
				fontSizeInput.type = "number";
				fontSizeInput.value = Std.string(font.size);
				fontSizeInput.min = "1";
				fontSizeInput.max = "200"; // This is the limit enforced in GMS2.3

				fontSizeInput.addEventListener("input", onSizeChanged);
				addOptionElement("Font size", fontSizeInput);
			}
			
			// Font range selection
			{
				rangeWindow = document.createDivElement();
				rangeWindow.id = "font-ranges";
				populateRanges();
				addOptionElement("Character ranges", rangeWindow);
			}

			// Font add range
			{
				var addRangeDiv = document.createDivElement();
				addRangeDiv.id = "add-range";
				{
					var newButton = document.createButtonElement();
					newButton.innerHTML = "Add range";
					newButton.addEventListener("click", function() {
						moreRangeOptionsDiv.style.display = "none";
						var newRange = {lower: 0x10FFFF, upper: 0x10FFFF};
						font.addRange(newRange);

						var rangeDiv = addRangeElement(newRange);

						rangeWindow.appendChild(rangeDiv);
						var input:InputElement = cast rangeDiv.getElementsByTagName("input")[0];
						input.value = "";
						input.select();
					});
					addRangeDiv.appendChild(newButton);
				}
	
				{
					var moreOptionsButton = document.createButtonElement();
					moreOptionsButton.innerHTML = "▼";
					moreOptionsButton.classList.add("more-options");
					moreOptionsButton.addEventListener("click", function() {
						moreRangeOptionsDiv.style.display = moreRangeOptionsDiv.style.display == "block" ? "none" : "block";
					});
					addRangeDiv.appendChild(moreOptionsButton);
					
				}
				optionsDiv.appendChild(addRangeDiv);

			
				moreRangeOptionsDiv = document.createDivElement();
				moreRangeOptionsDiv.classList.add("more-options-list");
				{
					var addCharacters = document.createButtonElement();
					addCharacters.innerHTML = "Add characters...";
					addCharacters.addEventListener("click", function() {
						Dialog.showPrompt("Characters to add to font:", "", function(newCharacters) {
							font.addCharacters(newCharacters);
							
							populateRanges();
							onFontChanged();
						});
					});
					moreRangeOptionsDiv.appendChild(addCharacters);
				}
	
				{
					var addAscii = document.createButtonElement();
					addAscii.innerHTML = "Add ASCII range";
					addAscii.addEventListener("click", function() {
						font.addRange({lower: 32, upper: 255});
	
						populateRanges();
						onFontChanged();
					});
					moreRangeOptionsDiv.appendChild(addAscii);
				}
	
				{
					var addAscii = document.createButtonElement();
					addAscii.innerHTML = "Add digits range";
					addAscii.addEventListener("click", function() {
						font.addRange({lower: 48, upper: 57});
	
						populateRanges();
						onFontChanged();
					});
					moreRangeOptionsDiv.appendChild(addAscii);
				}
	
				{
					var addLetters = document.createButtonElement();
					addLetters.innerHTML = "Add letters range";
					addLetters.addEventListener("click", function() {
						font.addRange({lower: 'A'.code, upper: 'Z'.code});
						font.addRange({lower: 'a'.code, upper: 'z'.code});
	
						populateRanges();
						onFontChanged();
					});
					moreRangeOptionsDiv.appendChild(addLetters);
				}
	
				optionsDiv.appendChild(moreRangeOptionsDiv);
			}

			// Regeneration warning
			{
				needsRegenerationWarning = document.createParagraphElement();
				needsRegenerationWarning.classList.add("regeneration-warning"); // straight outta doctor who
				needsRegenerationWarning.innerHTML = "The generated font file does not exist on disk. It is necessary to run the project inside GameMaker to create it.";	
				onImagefileChanged();
	
				optionsDiv.append(needsRegenerationWarning);
			}
	
			container.appendChild(optionsDiv);
		}


		{
			var previewArea = document.createDivElement();
			previewArea.id = "font-preview";

			{
				previewTextArea = document.createTextAreaElement();
				updatePreview();
				previewTextArea.addEventListener("input", onPreviewTextChanged);
				previewTextArea.addEventListener("blur", onPreviewTextLostFocus);
				previewArea.appendChild(previewTextArea);
			}

			{
				var previewHint = document.createParagraphElement();
				previewHint.classList.add("hint");
				previewHint.innerHTML = "Tip: Changing the characters inside this preview box will also change the font's included characters";
				previewArea.appendChild(previewHint);
			}

			container.appendChild(previewArea);

		}

		element.appendChild(container);
	}
}

private typedef FontFamily = {
	name: String,
	children: Array<FontDescriptor>
}