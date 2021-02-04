package editors;

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

class EditFont extends Editor {
	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		fontFamilies = new Dictionary();
	}

	private var font: YyFont;


	private var fontFamilies: Dictionary<FontFamily>;
	private var fontFamilySelect: SelectElement;
	private var fontStyleSelect: SelectElement;
	private var fontSizeInput: InputElement;
	private var previewWindow: DivElement;

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

		buildPage();

		FontScanner.getAvailableFonts().then(onFontsLoaded);
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
		if (newSize == font.size) {
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
	
	private function onFontChanged() {
		var fontDescriptor = getCurrentFont();
		if (fontDescriptor != null) {
			font.italic = fontDescriptor.italic;
		}
		// This looks hella weird because it is, but from my limited testing it seems to be how GM determines if it's a bold or not font as well
		font.bold = font.styleName.toLowerCase().indexOf("bold") >= 0;

		updatePreview();
	}

	/**Updates the size and font inside the preview-window*/
	private function updatePreview() {
		var fontDescriptor = getCurrentFont();
		
		if (fontDescriptor != null) {
			previewWindow.style.fontWeight = Std.string(fontDescriptor.weight);
			previewWindow.style.fontFamily = '"${fontDescriptor.postscriptName}", "${fontDescriptor.family} ${fontDescriptor.style}", "${fontDescriptor.family}"';
		} else {
			previewWindow.style.fontWeight = "500";
			previewWindow.style.fontFamily = '"${font.fontName} ${font.styleName}", "${font.fontName}"';
		}

		previewWindow.style.fontStyle = font.italic ? "italic" : "normal";
		previewWindow.style.fontSize = Std.string(font.size) + "pt";
	}

	// Sneakily put at the bottom so you never have to see it
	/**Builds the HTML page*/
	private function buildPage() {
		{
			var optionsDiv = document.createDivElement();

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
				optionsDiv.appendChild(fontFamilySelect);
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
				optionsDiv.appendChild(fontStyleSelect);
			}

			// Font size selection
			{
				fontSizeInput = document.createInputElement();
				fontSizeInput.type = "number";
				fontSizeInput.value = Std.string(font.size);
				fontSizeInput.min = "1";
				fontSizeInput.max = "200"; // This is the limit enforced in GMS2.3

				optionsDiv.addEventListener("input", onSizeChanged);
				optionsDiv.appendChild(fontSizeInput);
			}

			element.appendChild(optionsDiv);
		}


		{
			previewWindow = document.createDivElement();
			previewWindow.innerHTML = "ABCDefffgo m faomoiaofd sosaf gs   fgoks";

			element.appendChild(previewWindow);
		}

		updatePreview();
	}
}

private typedef FontFamily = {
	name: String,
	children: Array<FontDescriptor>
}