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
	/** A set of unrelated GML scripts joined together */
	Multifile;
	/** GLSL/GLSL ES shader */
	GLSL;
	/** HLSL shader (any version) */
	HLSL;
	/** JavaScript file (for editing extensions) */
	JavaScript;
	/** */
	GmxObjectEvents;
	GmxTimelineMoments;
	GmxProjectMacros;
	GmxConfigMacros;
	YyObjectEvents;
	YyTimelineMoments;
	/** Special type, results in opening vertex+fragment shaders as two tabs */
	YyShader;
	/** Find/replace results */
	SearchResults;
}
