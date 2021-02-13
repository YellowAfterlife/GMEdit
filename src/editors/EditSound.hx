package editors;

import tools.Random;
import js.html.AudioElement;
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
	}

	public override function save(): Bool {
		var newSoundJson = YyJson.stringify(sound, Project.current.yyExtJson);
		file.writeContent(newSoundJson);
		file.changed = false;
		
		return true;
	}


	private function callSoundChanged() {
		file.changed = true;
	}

	/**Called when the audio is ready. This is to extract the audio duration*/
	private function onAudioReady() {

	}


	private function importSound() {
		Dialog.showOpenDialog({
			title: "title goes here",
			buttonLabel: "button label",
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
			
			var thisPath = Path.withoutExtension(file.path);
			var newExtension = "." + Path.extension(newFile);
			FileSystem.copyFileSync(newFile, thisPath + newExtension);
			
			sound.soundFile = sound.name + newExtension;

			callSoundChanged();
			loadAudioElement();
		});
	}

	private function loadAudioElement() {
		audioElement.clearInner();
		if (sound.soundFile == null || sound.soundFile == "") {
			return;
		}
		var directory = Path.directory(file.path);
		// Adds some random noise to the end so it knows it needs to update
		audioElement.src = Path.join([directory, sound.soundFile]) + "?rnd=" + Random.letterString(8);
	}

	private function registerPageEvents() {

		var importButton = element.querySelector("#import_button");
		importButton.addEventListener("click", importSound);
		audioElement = cast element.querySelector("#audio_playback");
		audioElement.addEventListener("loadedmetadata", onAudioReady);
	}

	private function buildPageHtml() {

		element.innerHTML = SynSugar.xmls(<html>
			<h2>Name</h2>
			<button type="button" id="import_button" class="highlighted_button">Import audio</button>
			<audio id="audio_playback" controls></audio>
			<div>
				<input type="radio" name="compress_type" value="uncompressed">
				<label for="uncompressed">Uncompressed - Not Streamed</label><br>
				
				<input type="radio"  name="compress_type" value="compressed">
				<label for="compressed">Compressed - Not Streamed</label><br>
		
				<input type="radio"  name="compress_type" value="uncompressed_load">
				<label for="uncompressed_load">Uncompress on Load - Not Streamed</label><br>
		
				<input type="radio"  name="compress_type" value="compressed_streamed">
				<label for="compressed_streamed">Compressed - Streamed</label><br>
			</div> 
		
			<label>Output</label>
			<select>
				<option>Mono</option>
				<option>Stereo</option>
				<option>3D</option>
			</select>
		
			<label>Quality</label>
			<select>
				<option>8 bit</option>
				<option>16 bit</option>
			</select>
			
			<label>Sample Rate</label>
			<select>
				<option>5512</option>
				<option>11025</option>
				<option>22050</option>
				<option>32000</option>
				<option>44100</option>
				<option>48000</option>
			</select>
		
			<label>Bit Rate(kbps)</label>
			<select>
				<option>8</option>
				<option>16</option>
				<option>24</option>
				<option>32</option>
				<option>40</option>
				<option>48</option>
				<option>56</option>
				<option>64</option>
				<option>80</option>
				<option>96</option>
				<option>112</option>
				<option>128</option>
				<option>144</option>
				<option>160</option>
				<option>192</option>
				<option>224</option>
				<option>256</option>
				<option>320</option>
				<option>512</option>
			</select>
		</html>);
	}
}