(function() {
	//
	var Panner = $gmedit["editors.Panner"];
	var Editor = $gmedit["editors.Editor"];
	function ImageViewer(file) {
		Editor.call(this, file);
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
	ImageViewer.prototype = GMEdit.extend(Editor.prototype, {
		load: function(data) {
			this.image.src = this.file.path;
		}
	});
	//
	var FileKind = $gmedit["file.FileKind"];
	function KImage() {
		FileKind.call(this);
	}
	KImage.prototype = GMEdit.extend(FileKind.prototype, {
		init: function(file, data) {
			file.editor = new ImageViewer(file);
		}
	});
	//
	GMEdit.register("image-viewer", {
		init: function() {
			var kimg = new KImage();
			FileKind.register("png", kimg);
			FileKind.register("jpg", kimg);
			FileKind.register("gif", kimg);
			FileKind.register("bmp", kimg);
		},
		cleanup: function() {
			// todo
		}
	});
})();