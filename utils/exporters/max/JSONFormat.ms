function JSONDumpVertices src =
(
	Format "\"vertices\": [" to:ostream

	num = src.count

	if num > 0 then
	(
		for i = 1 to num do
		(
			vert = src[i]
			if flipYZ.checked then
			(
				x = vert.x
				y = vert.z
				z = vert.y
				z *= -1
			)
			else
			(
				x = vert.x
				y = vert.y
				z = vert.z
			)

			local vertexFormat = "%,%,%"
			Format vertexFormat x y z to:ostream
			if i < num then Format "," to:ostream				
		)
	)

	Format "],\n\n" to:ostream
	
	updateProgressSteps(1)
)

function JSONDumpNormals src = -- pks: I have no idea why it ostream is undefined when called from JSONDumpMorphTargets
(

	Format "\"normals\": [" to:ostream

	num = src.count

	if num > 0 and exportNormal.checked then
	(

		for i = 1 to num do
		(

			normal = src[i]
			normal = normalize normal as point3

			if flipYZ.checked then
			(

				x = normal.x
				y = normal.z
				z = normal.y

				z *= -1

			)
			else
			(

				x = normal.x
				y = normal.y
				z = normal.z

			)
			
			local vertexNormalFormat = "%,%,%"
			Format vertexNormalFormat x y z to:ostream

			if i < num then Format "," to:ostream

		)

	)

	Format "]\n\n" to:ostream

)


function JSONDumpMorphTargets src =
(
	Format "\"morphTargets\": [\n" to:ostream
	
	numMorphTargets = src.count
	numWritten = 0
	if numMorphTargets > 0 then
	(

		for i = 1 to numMorphTargets do
		(
			entry = src[i]
			frame = entry[1].frame as integer
			tagName = entry[2]
			normals = entry[4]
			vertices = entry[3]
			
			name = "frame_" + formattedPrint frame format:"06i"
			Format "    { \"name\": \"%\", \"keyframe\": %, \"action\": \"%\",\n      \"vertices\": [" name frame tagName to:ostream
			
			numVertices = vertices.count
			for j = 1 to vertices.count do
			(
				
				vert = vertices[j]
				if flipYZ.checked then
				(
					x = vert.x
					y = vert.z
					z = vert.y
					z *= -1
				)
				else
				(
					x = vert.x
					y = vert.y
					z = vert.z
				)

				local vertexFormat = "%,%,%"
				
				Format vertexFormat x y z to:ostream
				numWritten += 1
				if j < numVertices then Format "," to:ostream
			)
			Format "]" to:ostream
			
			Format ",\n      " to:ostream
			JSONDumpNormals normals
			
			Format "}" to:ostream
			if i < numMorphTargets then Format "," to:ostream
			Format "\n" to:ostream
			flush ostream
			
			if not (updateProgressSteps(1)) then 
				exit
		)

	)

	Format "]\n\n" to:ostream

)


function JSONDumpColors src useColors =
(

	Format "\"colors\": [" to:ostream

	num = src.count

	if num > 0 and useColors then
	(

		for i = 1 to num do
		(

			col = src[i]

			r = col.r as Integer
			g = col.g as Integer
			b = col.b as Integer

			hexNum = ( bit.shift r 16 ) + ( bit.shift g 8 ) + b

			-- hexColor = formattedPrint hexNum format:"#x"
			-- Format "%" hexColor to:ostream

			decColor = formattedPrint hexNum format:"#d"
			Format "%" decColor to:ostream

			if i < num then Format "," to:ostream

		)

	)

	Format "],\n\n" to:ostream

)


function JSONDumpUvs src =
(

	Format "\"uvs\": [[" to:ostream

	num = src.count

	if num > 0 and exportUv.checked then
	(

		for i = 1 to num do
		(

			uvw = src[i]

			u = uvw.x

			if flipUV.checked then
			(
				v = 1 - uvw.y
			)
			else
			(
				v = uvw.y
			)

			local UVFormat = "%,%"
			Format UVFormat u v to:ostream

			if i < num then Format "," to:ostream

		)

	)

	Format "]],\n\n" to:ostream

)

function JSONDumpFaces src useColors =
(

	Format "\"faces\": [" to:ostream

	num = src.count

	if num > 0 then
	(

		for i = 1 to num do
		(

			zface = src[i]

			fv  = zface[1]
			fuv = zface[2]
			m   = zface[3] - 1
			fc  = zface[4]

			needsFlip = zface[5]

			isTriangle = true
			hasMaterial = true
			hasFaceUvs = false
			hasFaceVertexUvs = ((classof fuv == Point3) and exportUv.checked)
			hasFaceNormals = false
			hasFaceVertexNormals = (exportNormal.checked)
			hasFaceColors = false
			hasFaceVertexColors = ((classof fc == Point3) and useColors)

			faceType = 0
			faceType = bit.set faceType 1 (not isTriangle)
			faceType = bit.set faceType 2 hasMaterial
			faceType = bit.set faceType 3 hasFaceUvs
			faceType = bit.set faceType 4 hasFaceVertexUvs
			faceType = bit.set faceType 5 hasFaceNormals
			faceType = bit.set faceType 6 hasFaceVertexNormals
			faceType = bit.set faceType 7 hasFaceColors
			faceType = bit.set faceType 8 hasFaceVertexColors

			if i > 1 then
			(
				Format "," faceType to:ostream
			)

			Format "%" faceType to:ostream

			if isTriangle then
			(

				va = (fv.x - 1) as Integer
				vb = (fv.y - 1) as Integer
				vc = (fv.z - 1) as Integer

				if flipFace.checked or needsFlip then
				(

					tmp = vb
					vb = vc
					vc = tmp

				)


				Format ",%,%,%" va vb vc to:ostream


				if hasMaterial then
				(

					Format ",%" m to:ostream

				)

				if hasFaceVertexUvs then
				(

					ua = (fuv.x - 1) as Integer
					ub = (fuv.y - 1) as Integer
					uc = (fuv.z - 1) as Integer

					if flipFace.checked or needsFlip then
					(

						tmp = ub
						ub = uc
						uc = tmp

					)

					Format ",%,%,%" ua ub uc to:ostream

				)

				if hasFaceVertexNormals then
				(

					if smoothNormal.state == 1 then -- vertex normals
					(

						-- normals have the same indices as vertices

						na = va
						nb = vb
						nc = vc

					)
					else
					(
						-- normals have the same indices as face

						na = i - 1
						nb = na
						nc = na

					)

					if flipFace.checked or needsFlip then
					(

						tmp = nb
						nb = nc
						nc = tmp

					)

					Format ",%,%,%" na nb nc to:ostream

				)


				if hasFaceVertexColors then
				(

					ca = (fc.x - 1) as Integer
					cb = (fc.y - 1) as Integer
					cc = (fc.z - 1) as Integer

					if flipFace.checked or needsFlip then
					(

						tmp = cb
						cb = cc
						cc = tmp

					)

					Format ",%,%,%" ca cb cc to:ostream

				)

			)

		)

	)

	Format "],\n\n" to:ostream

)

function JSONDumpColor pcolor label =
(
	r = pcolor.r / 255
	g = pcolor.g / 255
	b = pcolor.b / 255

	fr = formattedPrint r format:".4f"
	fg = formattedPrint g format:".4f"
	fb = formattedPrint b format:".4f"

	Format "\"%\"  : [%, %, %],\n" label fr fg fb to:ostream

)

function JSONDumpMap pmap label =
(

	if classof pmap == BitmapTexture then
	(
		bm = pmap.bitmap

		if bm != undefined then
		(

			fname = filenameFromPath bm.filename
			Format "\"%\"    : \"%\",\n" label fname to:ostream

		)

	)

)

function JSONDumpMaterials zmaterials zcolors =
(

	Format "\"materials\": [\n" to:ostream

	totalMaterials = zmaterials.count

	for i = 1 to totalMaterials do
	(
		mat = zmaterials[i]

		Format "{\n" to:ostream

		-- debug

		Format "\"DbgIndex\" : %,\n" (i-1) to:ostream

		if classof mat != BooleanClass then
		(

			useVertexColors = zcolors[i]

			Format "\"DbgName\"  : \"%\",\n" mat.name to:ostream

			-- colors

			JSONDumpColor mat.diffuse  "colorDiffuse"
			JSONDumpColor mat.ambient  "colorAmbient"
			JSONDumpColor mat.specular "colorSpecular"

			t = mat.opacity / 100
			s = mat.glossiness

			Format "\"transparency\"  : %,\n" t to:ostream
			Format "\"specularCoef\"  : %,\n" s to:ostream

			-- maps

			JSONDumpMap mat.diffuseMap  "mapDiffuse"
			JSONDumpMap mat.ambientMap  "mapAmbient"
			JSONDumpMap mat.specularMap "mapSpecular"
			JSONDumpMap mat.bumpMap 	"mapBump"
			JSONDumpMap mat.opacityMap 	"mapAlpha"

		)
		else
		(

			useVertexColors = false

			Format "\"DbgName\"  : \"%\",\n" "dummy" to:ostream

			JSONDumpColor red "colorDiffuse"

		)

		Format "\"vertexColors\" : %\n" useVertexColors to:ostream
		Format "}" to:ostream

		if ( i < totalMaterials ) then Format "," to:ostream
		Format "\n\n" to:ostream

	)

	Format "],\n\n" to:ostream

)


function JSONDumpScene parts =
(	
	
	
	inObjects = parts[1]
	inVertices = parts[2]
	inNormals = parts[3]
	inColors = parts[4]
	inUvs = parts[5]
	inFaces = parts[6]
	inMaterials = parts[7]
	inMaterialsColors = parts[8]
	inMorphTargets = parts[9]
	
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

	ostream = CreateFile (sysInfo.tempdir + "\\ThreeJSExport.temp.txt")

	Format "{\n\n" to:ostream

	local headerFormat = "\"metadata\":
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
},

"
	
	Format headerFormat maxFileName totalVertices totalNormals totalColors totalUvs totalFaces totalMaterials totalMorphTargets objectName to:ostream

	JSONDumpMaterials inMaterials inMaterialsColors
	
	JSONDumpVertices inVertices
	flush ostream
	if canceled then return null
		
	JSONDumpNormals inNormals
	Format "," to:ostream
	JSONDumpColors inColors useColors
	JSONDumpUvs inUvs
	JSONDumpFaces inFaces useColors	
	JSONDumpMorphTargets inMorphTargets
	if canceled then return null	
	flush ostream

	Format "}\n" to:ostream
	close ostream
	
	data = (dotnetClass "System.IO.File").ReadAllText  (sysInfo.tempdir + "\\ThreeJSExport.temp.txt")
	(dotnetClass "System.IO.File").WriteAllText (filePath + ".js") data
	(dotnetClass "System.IO.File").Delete  (sysInfo.tempdir + "\\ThreeJSExport.temp.txt")
)
