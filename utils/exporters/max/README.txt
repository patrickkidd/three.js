The max exporter now has two scripts (ThreeJSExporter.ms, JSONFormat.ms) in order to support output format plugins. BinaryFormat.ms is incomplete and will be implemented in time to allow for bigger animated models.

***** TO MAKE A MAX SCRIPT PACKAGE:

1) Create a zip file containing (only!) the following files in the root dir:

	- max.run (MAXScript package entry point)
	- ThreeJSExporter.ms (root script)
	- JSONFormat.ms (JSON format support)

2) Rename the zip file to "ThreeJSExporter.mzp"

3) Run the maxscript package by choosing "MAXScript" -> "Run Script…" in 3DsMAX


ALTERNATIVELY, you can run the script without creating a package by simply executing "ThreeJSExporter.ms" from a folder on your hard drive, assuming that JSONFormat.ms exists in the same folder.

CHANGES:

May 16th 2012:
========================================================================
- morph targets w/ morph normals
- update gui while animating
- MAX object name
- MAX TimeTag-based animation actions.
- support for multiple output formats (binary format planned for future)
- run as mzp MAXScript package
- can write to network drives (important for offices with many modelers)
- progress bar / cancel button (extreme necessity for big models)
- save objects into separate named .js files
- select all selection
- merge selection into single model
- name merged selection
- store / recall per-scene script preferences



Contact me with any questions:

Patrick Stinson
patrickkidd@gmail.com

