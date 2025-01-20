(function() {
	//
	const Panner = $gmedit["editors.Panner"];
	const Editor = $gmedit["editors.Editor"];
	const FileKind = $gmedit["file.FileKind"];

	class ImageViewer extends Editor {

		constructor(file) {

			super(file);
			
			this.element = document.createElement("div");
			this.element.classList.add("resinfo");
			this.element.classList.add("sprite");
			//
			var panner = null;
			var pandiv = document.createElement("div");
			this.element.appendChild(pandiv);
			//
			var image = document.createElement("img");
			image.onload = function(_) {
				panner.recenter();
			};
			pandiv.appendChild(image);
			this.image = image;
			//
			panner = new Panner(pandiv, image);
			this.panner = panner;
			
		}

		load(_) {
			this.image.src = this.file.path;
		}

	}

	class KImage extends FileKind {

		static inst = new KImage();

		init(file, _) {
			file.editor = new ImageViewer(file);
		}

	}

	GMEdit.register("image-viewer", {
		init: function() {
			FileKind.register("png", KImage.inst);
			FileKind.register("jpg", KImage.inst);
			FileKind.register("jpeg", KImage.inst);
			FileKind.register("gif", KImage.inst);
			FileKind.register("bmp", KImage.inst);
		},
		cleanup: function() {
			FileKind.deregister("png", KImage.inst);
			FileKind.deregister("jpg", KImage.inst);
			FileKind.deregister("jpeg", KImage.inst);
			FileKind.deregister("gif", KImage.inst);
			FileKind.deregister("bmp", KImage.inst);
		}
	});
})();