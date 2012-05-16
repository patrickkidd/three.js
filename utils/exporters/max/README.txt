The max exporter now has two scripts (ThreeJSExporter.ms, JSONFormat.ms) in order to support output format plugins. BinaryFormat.ms is incomplete and will be implemented in time to allow for bigger animated models.

***** TO MAKE A MAX SCRIPT PACKAGE:

1) Create a zip file containing (only!) the following files in the root dir:

	- max.run (MAXScript package entry point)
	- ThreeJSExporter.ms (root script)
	- JSONFormat.ms (JSON format support)

2) Rename the zip file to "ThreeJSExporter.mzp"

3) Run the maxscript package by choosing "MAXScript" -> "Run Script…" in 3DsMAX


ALTERNATIVELY, you can run the script without creating a package by simply executing "ThreeJSExporter.ms" from a folder on your hard drive, assuming that JSONFormat.ms exists in the same folder.

Contact me with any questions:

Patrick Stinson
patrickkidd@gmail.com

