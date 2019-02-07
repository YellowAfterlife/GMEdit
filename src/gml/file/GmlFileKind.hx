package gml.file;

/**
 * File kind determines how the file data is interpreted and packed back upon saving.
 * @author YellowAfterlife
 */
enum GmlFileKind {
	/** Marks things that cannot be opened in GMEdit itself */
	Extern;
	
	/** Plaintext - no highlighting */
	Plain;
	
	/** GML scripts (possibly with sub-scripts) */
	Normal;
	
	/** GML file in an YY/GMX extension */
	ExtGML;
	
	/** A set of unrelated GML scripts joined together */
	Multifile;
	
	/** GLSL/GLSL ES shader */
	GLSL;
	
	/** HLSL shader (any version) */
	HLSL;
	
	/** JavaScript file (for editing extensions) */
	JavaScript;
	
	//{ GMS1 specific
	/** Combined object event view */
	GmxObjectEvents;
	
	/** Combined timeline moment view */
	GmxTimelineMoments;
	
	/** Macros inside a .project.gmx */
	GmxProjectMacros;
	
	/** Macros inside a .config.gmx */
	GmxConfigMacros;
	//}
	
	//{ GMS2 specific
	/** Combined object event view */
	YyObjectEvents;
	
	/** Combined timeline moment view */
	YyTimelineMoments;
	
	/** Special type, results in opening vertex+fragment shaders as two tabs */
	YyShader;
	
	GmxSpriteView;
	YySpriteView;
	
	GmxExtensionAPI;
	YyExtensionAPI;
	
	/** Combined room creation codes */
	YyRoomCCs;
	//}
	
	/** Find/replace results */
	SearchResults;
	
	/** Snippets editor */
	Snippets;
	
	/** Only used for special-case parsing */
	LambdaGML;
	
	Markdown;
	DocMarkdown;
}
