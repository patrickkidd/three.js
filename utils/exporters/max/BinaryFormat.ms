struct BinaryExporter
(
	data = undefined,
	jsFile,
	binFile,
	headerFormat = "{
		\"metadata\":
		{
			\"sourceFile\": \"%\",
			\"generatedBy\": \"3ds max ThreeJSExporter\",
			\"formatVersion\": 3,
			\"vertices\": %,
			\"normals\": %,
			\"colors\": %,
			\"uvs\": %,
			\"triangles\": %,
			\"materials\": %,
			\"morphTargets\": %,
			\"name\": \"%\"
		}
		}
",
		
	fn WriteHeader =
	(

        -- signature
		binFile.WriteString "Three.js 003"

        -- metadata (all data is little-endian)
        vertex_coordinate_bytes = 4
        normal_coordinate_bytes = 1
        uv_coordinate_bytes = 4
    
        vertex_index_bytes = 4
        normal_index_bytes = 4
        uv_index_bytes = 4
        material_index_bytes = 2
        
	    header_bytes = 0
	    header_bytes += 12   -- signature
	    header_bytes += 8    -- header
	    header_bytes += 44   -- ndata
        binFile.WriteByte header_bytes
        binFile.WriteByte vertex_coordinate_bytes
        binFile.WriteByte normal_coordinate_bytes
        binFile.WriteByte uv_coordinate_bytes
        binFile.WriteByte vertex_index_bytes
        binFile.WriteByte normal_index_bytes
        binFile.WriteByte uv_index_bytes
        binFile.WriteByte material_index_bytes
        
        
        
        
    ntri_flat = len(sfaces['triangles_flat'])
    ntri_smooth = len(sfaces['triangles_smooth'])
    ntri_flat_uv = len(sfaces['triangles_flat_uv'])
    ntri_smooth_uv = len(sfaces['triangles_smooth_uv'])

    nquad_flat = len(sfaces['quads_flat'])
    nquad_smooth = len(sfaces['quads_smooth'])
    nquad_flat_uv = len(sfaces['quads_flat_uv'])
    nquad_smooth_uv = len(sfaces['quads_smooth_uv'])

    # nvertices       unsigned int    4
    # nnormals        unsigned int    4
    # nuvs            unsigned int    4

    # ntri_flat       unsigned int    4
    # ntri_smooth     unsigned int    4
    # ntri_flat_uv    unsigned int    4
    # ntri_smooth_uv  unsigned int    4

    # nquad_flat      unsigned int    4
    # nquad_smooth    unsigned int    4
    # nquad_flat_uv   unsigned int    4
    # nquad_smooth_uv unsigned int    4
    ndata = struct.pack('<IIIIIIIIIII', len(vertices),
                               nnormals,
                               len(uvs),
                               ntri_flat,
                               ntri_smooth,
                               ntri_flat_uv,
                               ntri_smooth_uv,
                               nquad_flat,
                               nquad_smooth,
                               nquad_flat_uv,
                               nquad_smooth_uv)
        

	)
	
	fn WriteVertices =
	(
		
	)
	
	
	
	fn WriteScene = 
	(
		inObjects = data[1]
		inVertices = data[2]
		inNormals = data[3]
		inColors = data[4]
		inUvs = data[5]
		inFaces = data[6]
		inMaterials = data[7]
		inMaterialsColors = data[8]
		inMorphTargets = data[9]

		totalVertices = inVertices.count
		totalMorphTargets = inMorphTargets.count
		totalFaces = inFaces.count
		totalMaterials = inMaterials.count

		totalColors = 0
		totalNormals = 0
		totalUvs = 0

		useColors = false

		if exportNormal.checked then totalNormals = inNormals.count
		if exportUv.checked then totalUvs = inUvs.count
		if sceneHasVColors and exportColor.checked then
		(
			totalColors = inColors.count
			useColors = true
		)

		jsFile = CreateFile filePath + ".js"
		Format headerFormat maxFileName totalVertices totalNormals totalColors totalUvs totalFaces totalMaterials totalMorphTargets objectName to:jsFile
		close jsFile

		binPath = filePath + ".bin"
		binFile = BinStream binPath 'wb'

		WriteHeader
		BinaryDumpMaterials inMaterials inMaterialsColors

		BinaryDumpVertices inVertices
		flush binFile
		if canceled then return null

		BinaryDumpMorphTargets inMorphTargets
		flush binFile
		if canceled then return null

		BinaryDumpNormals inNormals
		BinaryDumpColors inColors useColors
		BinaryDumpUvs inUvs
		BinaryDumpFaces inFaces useColors

		close binFile
	)
)

