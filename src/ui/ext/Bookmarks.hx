package ui.ext;
import ace.AceWrap;
import ace.extern.AceAnchor;
import ace.extern.AceAnnotation;
import ace.extern.AceDocument;
import ace.extern.AceSession;
import gml.GmlAPI.GmlLookup;
import gml.file.GmlFile;
import tools.Aliases;
import ui.OpenDeclaration;

/**
 * ...
 * @author YellowAfterlife
 */
class Bookmarks {
	public static var current:Array<GmlBookmark> = [];
	static function sync(bookmark:GmlBookmark) {
		if (bookmark.anchor == null) return;
		bookmark.row = bookmark.anchor.row;
		bookmark.col = bookmark.anchor.column;
	}
	public static function getStates():Array<GmlBookmarkState> {
		return current.map(function(bm) {
			if (bm == null) return null;
			sync(bm);
			return { path: bm.path, row: bm.row, col: bm.col };
		});
	}
	public static function setStates(arr:Array<GmlBookmarkState>) {
		current = [];
		if (arr != null) for (i => bms in arr) {
			var bm:GmlBookmark;
			if (bms == null) {
				bm = null;
			} else bm = {
				path: bms.path,
				row: bms.row,
				col: bms.col,
				doc: null,
				anchor: null,
				bookmarkName: "Bookmark " + (i + 1)
			};
			current.push(bm);
		}
	}
	
	public static function open(editor:AceWrap, index:Int) {
		var bm = current[index];
		if (bm == null) return;
		sync(bm);
		//Console.log(bm);
		OpenDeclaration.openLookup(bm);
	}
	
	static function bind(bm:GmlBookmark, doc:AceDocument, index:Int) {
		bm.anchor = doc.createAnchor(bm.row, bm.col);
		(cast bm.anchor).bookmarkName = bm.bookmarkName;
		bm.doc = doc;
		
		if (doc.gmlBookmarks == null) doc.gmlBookmarks = [];
		doc.gmlBookmarks.push(bm.anchor);
	}
	
	public static function toggle(editor:AceWrap, index:Int) {
		var session = editor.session;
		var file = session.gmlFile;
		if (file == null) return;
		var lead = session.selection.lead;
		
		var curr = current[index];
		var wantAdd = true;
		if (curr != null) {
			sync(curr);
			wantAdd = (curr.path != file.path || curr.row != lead.row);
			
			if (curr.anchor != null) {
				curr.anchor.detach();
				var doc = curr.anchor.getDocument();
				if (doc.gmlBookmarks != null) {
					doc.gmlBookmarks.remove(curr.anchor);
				}
			}
		}
		if (wantAdd) {
			var doc = session.doc;
			var next:GmlBookmark = {
				path: file.path,
				row: lead.row,
				col: lead.column,
				doc: null,
				anchor: null,
				bookmarkName: "Bookmark " + (index + 1)
			};
			bind(next, doc, index);
			//
			current[index] = next;
		} else {
			current[index] = null;
		}
		editor.renderer.__gutter.update((cast editor.renderer).layerConfig);
	}
	public static function onFileOpen(file:GmlFile) {
		var path = file.path;
		if (path == null) return;
		
		var session = file.getAceSession();
		if (session == null) return;
		
		var doc = session.doc;
		
		for (i => bm in current) {
			if (bm != null && bm.path == path) {
				bind(bm, doc, i);
			}
		}
	}
	public static function onFileClose(file:GmlFile) {
		if (file.path == null) return;
		
		var session = file.getAceSession();
		if (session == null) return;
		
		var doc = session.doc;
		for (bm in current) if (bm != null && bm.doc == doc) {
			sync(bm);
			bm.anchor.detach();
			bm.anchor = null;
			bm.doc = null;
		}
	}
}
typedef GmlBookmark = { > GmlLookup,
	doc:AceDocument,
	anchor:AceAnchor,
	bookmarkName:String,
};
typedef GmlBookmarkState = {
	path:FullPath,
	row:Int,
	col:Int,
};
