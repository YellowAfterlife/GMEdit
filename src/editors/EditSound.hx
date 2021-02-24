package editors;

import js.html.*;
import tools.Random;
import yy.YyJson;
import haxe.io.Path;
import electron.FileSystem;
import tools.macros.SynSugar;
import file.kind.yy.KYySound;
import electron.FileWrap;
import electron.Dialog;
import gml.Project;
import yy.YySound;
import gml.file.GmlFile;
import Main.document;
using tools.HtmlTools;

class EditSound extends Editor {
	public function new(file:GmlFile) {
		super(file);
		element = document.createDivElement();
		element.id = "sound-editor";
		
	}

	private var sound: YySound;

	private var audioElement: AudioElement;
	private var soundVolumeSlider: InputElement;
	private var soundVolumeText: InputElement;

	private var saveOnFinishLoad = false;

	public override function load(data:Dynamic) {
		super.load(data);

		if (Std.is(file.kind, KYySound) == false) {
			return;
		}

		if (data == null) data = FileWrap.readYyFileSync(file.path);
		if (data == null) {
			return;
		}

		if (Project.current.yyUsesGUID ) {
			Dialog.showAlert("Sound editing is not supported for the version used by this project");
			return;
		}

		sound = data;

		buildPageHtml();
	}

	public override function ready() {
		registerPageEvents();
		loadAudioElement();
		setOptionValues();
	}

	public override function save(): Bool {
		var newSoundJson = YyJson.stringify(sound, Project.current.yyExtJson);
		file.writeContent(newSoundJson);
		file.changed = false;
		
		return true;
	}

	/**Returns the full path of the current sound file*/
	private function getSoundPath(): String {
		if (sound.soundFile == null || sound.soundFile == "") {
			return "";
		}
		var directory = Path.directory(file.path);
		return Path.join([directory, sound.soundFile]);
	}


	private function invokeSoundChanged() {
		file.changed = true;
	}

	/**Called when the audio is ready. This is to extract the audio duration*/
	private function onAudioReady() {
		var newDuration = audioElement.duration;
		if (newDuration == 0 || newDuration == Math.NaN || newDuration == Math.POSITIVE_INFINITY) {
			return;
		}
		// There's tiny differences in duration from GMs reported duration and electrons. So we dont update the font when in fact it's the same file
		// add a small epsilon. Duration is set to 0 on start of load audio so this should not have false negatives.
		if (Math.abs(sound.duration - audioElement.duration) > 0.01) {
			sound.duration = audioElement.duration;
			invokeSoundChanged();
		}

		if (saveOnFinishLoad) {
			saveOnFinishLoad = false;
			save();
		}
	}


	private function importSound() {
		Dialog.showOpenDialog({
			title: "Open",
			buttonLabel: "Import",
			filters: [
				new DialogFilter( "Audio files", ["mp3", "ogg", "wav", "wma"])
			]
		}, function(array: Array<String>) {
			if (array == null || array.length == 0) {
				return;
			}

			var newFile = array[0];
			
			if (FileSystem.existsSync(newFile) == false) {
				Dialog.showAlert("File not found:\n" + newFile);
				return;
			}
			
			// Remove the old file
			var old = getSoundPath();
			if (old != "") {
				FileSystem.unlinkSync(old);
			}

			var thisPath = Path.withoutExtension(file.path);
			var newExtension = "." + Path.extension(newFile);
			FileSystem.copyFileSync(newFile, thisPath + newExtension);
			
			sound.soundFile = sound.name + newExtension;
			// So it's changed when the sound finishes loading
			sound.duration = 0;

			// Once the sound is loaded we want the duration to be saved to file
			saveOnFinishLoad = true;

			invokeSoundChanged();
			loadAudioElement();
			
			// A save to save the new path, since we can get stray files otherwise.
			save();
		});
	}

	private function loadAudioElement() {
		audioElement.clearInner();
		if (sound.soundFile == null || sound.soundFile == "") {
			return;
		}
		// Adds some random noise to the end so it knows it needs to update
		var soundPath = getSoundPath() + "?rnd=" + Random.letterString(8);
		
		audioElement.src = soundPath;
	}

	private function onVolumeSliderChanged(event: Event) {
		sound.volume = Math.round( 100 * Std.parseFloat( soundVolumeSlider.value ))/100;
		soundVolumeText.value = Std.string(sound.volume);
		invokeSoundChanged();
	}

	/**A small preview on the text element that doesn't update constantly*/
	private function onVolumeSliderInput(event: Event) {
		soundVolumeText.value = Std.string(Math.round( 100 * Std.parseFloat( soundVolumeSlider.value ))/100);
	}

	private function onVolumeTextChanged(event: Event) {
		sound.volume = Math.round( 100 * Std.parseFloat( soundVolumeText.value ))/100;
		soundVolumeSlider.value = Std.string(sound.volume);
		invokeSoundChanged();
	}

	private function onCompressionChanged(event: Event) {
		var inputElement:InputElement = cast event.target;
		sound.compression = Std.parseInt(inputElement.value);
		invokeSoundChanged();
	}

	private function onOutputChanged(event: Event) {
		var select:SelectElement = cast event.target;
		sound.type = Std.parseInt(select.value);
		invokeSoundChanged();
	}

	private function onQualityChanged(event: Event) {
		var select:SelectElement = cast event.target;
		sound.bitDepth = Std.parseInt(select.value);
		invokeSoundChanged();
	}

	private function onSampleRateChanged(event: Event) {
		var select:SelectElement = cast event.target;
		sound.sampleRate = Std.parseInt(select.value);
		invokeSoundChanged();
	}

	private function onBitRateChanged(event: Event) {
		var select:SelectElement = cast event.target;
		sound.bitRate = Std.parseInt(select.value);
		invokeSoundChanged();
	}

	/**Register the events on elements. Should only be called once*/
	private function registerPageEvents() {

		var importButton = element.querySelector("#import-button");
		importButton.addEventListener("click", importSound);

		audioElement = cast element.querySelector("#sound-playback");
		audioElement.addEventListener("loadedmetadata", onAudioReady);

		soundVolumeSlider = cast element.querySelector("#sound-volume-slider");
		soundVolumeSlider.addEventListener("change", onVolumeSliderChanged);
		soundVolumeSlider.addEventListener("input", onVolumeSliderInput);

		soundVolumeText = cast element.querySelector("#sound-volume-text");
		soundVolumeText.addEventListener("change", onVolumeTextChanged);

		var soundCompress = element.querySelector("#sound-compress-type");
		for (child in soundCompress.querySelectorAll("input[name=\"compress-type\"]")) {
			child.addEventListener("change", onCompressionChanged);
		}

		var soundOutput = element.querySelector("#sound-output");
		soundOutput.addEventListener("change", onOutputChanged);

		var soundQuality = element.querySelector("#sound-quality");
		soundQuality.addEventListener("change", onQualityChanged);

		var soundSampleRate = element.querySelector("#sound-sample-rate");
		soundSampleRate.addEventListener("change", onSampleRateChanged);

		var soundBitRate = element.querySelector("#sound-bit-rate");
		soundBitRate.addEventListener("change", onBitRateChanged);
	}


	/**Updates all values on the page to reflect whatever is inside the current sound*/
	private function setOptionValues() {
		var header = element.querySelector("h2");
		header.innerText = sound.name;

		soundVolumeSlider.value = Std.string(sound.volume);

		soundVolumeText.value = Std.string(sound.volume);
		
		var soundCompress = element.querySelector("#sound-compress-type");
		for (genericChild in soundCompress.querySelectorAll("input[name=\"compress-type\"]")) {
			var child:InputElement = cast genericChild;
			if (Std.string(sound.compression) == child.value) {
				child.checked = true;
				break;
			}
		}

		function setSelectedValueForSelect(selectId: String, value:Int) {
			var parent = element.querySelector('#${selectId}');
			var value:OptionElement = cast parent.querySelector('option[value="${value}"]');
			if (value != null) {
				value.selected = true;
			} else {
				Console.log('Did not find audio option ${value} for selector ${selectId}');
			}
		}

		setSelectedValueForSelect("sound-output", sound.type);
		
		setSelectedValueForSelect("sound-quality", sound.bitDepth);

		setSelectedValueForSelect("sound-sample-rate", sound.sampleRate);

		setSelectedValueForSelect("sound-bit-rate", sound.bitRate);
	}

	private function buildPageHtml() {

		element.innerHTML = SynSugar.xmls(<html>
			<div>
				<h2>Name</h2>
				<button type="button" id="import-button" class="highlighted-button">Import audio</button>
				
				<label>Preview</label>
				<audio id="sound-playback" controls></audio>
				
				<div class="option">
					<label>Volume</label>
					<div id="sound-volume-container">
						<input id="sound-volume-slider" type="range" min="0" max="1" step="0.001"/>
						<input id="sound-volume-text" type="number" min="0" max="1" step="0.01"/> 
					</div>
				</div>

				<div class="option">
					<label>Compression Type</label>
					<div id="sound-compress-type">
						<div title="Audio is uncompresssed and stored in memory. Low CPU usage at the cost of storage. Good for short frequently used sound effects.">
							<input type="radio" name="compress-type" id="uncompressed" value="0">
							<label for="uncompressed">Uncompressed - Not Streamed</label><br>
						</div>

						<div title="Audio is compressed at all times. Heavier on the CPU but reduces storage. Good for long sound effects that are infrequently used.">
							<input type="radio" name="compress-type" id="compressed" value="1">
							<label for="compressed">Compressed - Not Streamed</label><br>
						</div>

						<div title="Audio is uncompressed on game startup. Increases start up time but reduces storage. Good for long sound effects that are frequently used.">
							<input type="radio" name="compress-type" id="uncompressed-load" value="2">
							<label for="uncompressed-load">Uncompress on Load - Not Streamed</label><br>
						</div>

						<div title="Audio is compressed and streamed from disk, reducing storage size at the cost of being heavier on the CPU. Good for music.">
							<input type="radio" name="compress-type" id="compressed-streamed" value="3">
							<label for="compressed-streamed">Compressed - Streamed</label><br>
						</div>
					</div> 
				</div> 
				
				<div class="option">
					<label>Output</label>
					<select id="sound-output">
						<option value="0">Mono</option>
						<option value="1">Stereo</option>
						<option value="2">3D</option>
					</select>
				</div>

				<div class="option">
					<label>Quality</label>
					<select id="sound-quality">
						<option value="0">8 bit</option>
						<option value="1">16 bit</option>
					</select>
				</div>
				
				<div class="option">
					<label>Sample Rate</label>
					<select id="sound-sample-rate">
						<option value="5512">5512</option>
						<option value="11025">11025</option>
						<option value="22050">22050</option>
						<option value="32000">32000</option>
						<option value="44100">44100</option>
						<option value="48000">48000</option>
					</select>
				</div>
			
				<div class="option">
					<label>Bit Rate(kbps)</label>
					<select id="sound-bit-rate">
						<option value="8">8</option>
						<option value="16">16</option>
						<option value="24">24</option>
						<option value="32">32</option>
						<option value="40">40</option>
						<option value="48">48</option>
						<option value="56">56</option>
						<option value="64">64</option>
						<option value="80">80</option>
						<option value="96">96</option>
						<option value="112">112</option>
						<option value="128">128</option>
						<option value="144">144</option>
						<option value="160">160</option>
						<option value="192">192</option>
						<option value="224">224</option>
						<option value="256">256</option>
						<option value="320">320</option>
						<option value="512">512</option>
					</select>
				</div>
			</div>
		</html>);

		
	}
}