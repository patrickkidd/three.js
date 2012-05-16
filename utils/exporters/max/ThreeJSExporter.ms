-------------------------------------------------------------------------------------
-- ThreeJSExporter.ms
-- Exports geometry from 3ds max to Three.js models in ASCII JSON format v3
-- By alteredq / http://alteredqualia.com
-------------------------------------------------------------------------------------


rollout ThreeJSExporter "ThreeJSExporter"
(
	-- Variables

	local ostream,
	
	iniPath,
	
	outputFormats = #("JSON"), -- , "Binary"),
	OUTPUT_FORMAT = undefined,
	sceneHasVColors = false,
	filePath,

	timeTags,
	
	canceled = false,
	numProgressStepsTotal = 0,
	numProgressSteps = 0

	-------------------------------------------------------------------------------------
	-- User interface


	group "ThreeJSExporter  v0.9"
	(

		label msg "Exports selected meshes in Three.js ascii JSON format" align:#left
		hyperLink lab1 "Original source at GitHub" address:"https://github.com/alteredq/three.js/blob/master/utils/exporters/max/ThreeJSExporter.ms" color:(color 255 120 0) align:#left

        radioButtons exportFormat "Output Format" labels:outputFormats default:1

		label dummy4 "--------------------------------------------------------" align:#left
		
		checkbox exportSelectAll "Select All" checked:true enabled:true
		checkbox exportMergeObjects "Merge selection into single mesh" checked:false enabled:true
		edittext exportMergeObjectName "Merged object name" enabled:true visible:false
		
		label dummy1 "--------------------------------------------------------" align:#left

		checkbox exportColor "Export vertex colors" checked:false enabled:true
		checkbox exportUv "Export uvs" checked:true enabled:true
		checkbox exportNormal "Export normals" checked:true enabled:true
		radioButtons smoothNormal "" labels:#("Vertex normals", "Face normals") default:1 enabled:true

		label dummy2 "--------------------------------------------------------" align:#left

		checkbox flipYZ "Flip YZ" checked:true enabled:true
		checkbox flipUV "Flip UV" checked:true enabled:true
		checkbox flipFace "Flip all faces" checked:false enabled:true
		checkbox autoflipFace "Try fixing flipped faces" checked:false enabled:true

		label dummy3 "--------------------------------------------------------" align:#left		
		label msg1 "Animation" align:#center
		checkbox exportAnimateEnable "Morph Targets" checked:false enabled:true
		checkbox exportAnimateOnlyKeyframes "Key Frames Only" checked:false enabled:true visible:false
--		checkbox exportAnimateUpdateGui "Update GUI" checked:false enabled:true visible:false
				
		button btn_export "Export"
	)

	
	function updateProgressSteps steps =
	(
		numProgressSteps += steps
		percent = 100.0 * numProgressSteps / numProgressStepsTotal
		if not progressUpdate(percent) then
		(
			windows.processPostedMessages()
			canceled = true
			return false
		)
		windows.processPostedMessages()
		return true
	)

	include "JSONFormat.ms"
	-- include "BinaryFormat.ms"
	
	
	
	-------------------------------------------------------------------------------------
	-- Extract vertices from mesh

	function ExtractVertices obj whereto =
	(
		n = obj.numVerts

		for i = 1 to n do
		(

			v = GetVert obj i
			append whereto v

		)

	)
	
	-------------------------------------------------------------------------------------
	-- Extract vertex colors from mesh

	function ExtractColors obj whereto =
	(

		nColors = GetNumCPVVerts obj

		if nColors > 0 then
		(

			for i = 1 to nColors do
			(

				c = GetVertColor obj i
				append whereto c

			)

		)

	)


	-------------------------------------------------------------------------------------
	-- Extract normals from mesh
	function ExtractNormals obj whereto needsFlip =
	(

		if smoothNormal.state == 1 then -- vertex normals
		(

			num = obj.numVerts

			for i = 1 to num do
			(
				
				n = GetNormal obj i

				if flipFace.checked or needsFlip then
				(
					n.x *= -1
					n.y *= -1
					n.z *= -1
					
				)

				append whereto n

			)

		)
		else -- face normals
		(

			num = obj.numFaces

			for i = 1 to num do
			(

				n = GetFaceNormal obj i

				if flipFace.checked or needsFlip then
				(
					n.x *= -1
					n.y *= -1
					n.z *= -1
				)

				append whereto n

			)

		)

	)

	-------------------------------------------------------------------------------------
	-- Extract uvs from mesh

	function ExtractUvs obj whereto =
	(
		n = obj.numTVerts

		for i = 1 to n do
		(

			v = GetTVert obj i
			append whereto v

		)

	)

	-------------------------------------------------------------------------------------
	-- Extract faces from mesh

	function ExtractFaces objMesh objMaterial whereto allMaterials needsFlip hasVColors offsetVert offsetUv offsetColor =
	(
		n = objMesh.numFaces
		hasUVs = objMesh.numTVerts > 0

		useMultiMaterial = false
		materialIDList = #()

		materialClass = classof objMaterial

		if materialClass == StandardMaterial then
		(

			fm = findItem allMaterials objMaterial

		)
		else if materialClass == MultiMaterial then
		(

			useMultiMaterial = true

			for i = 1 to n do
			(

				mID = GetFaceMatID objMesh i
				materialIndex = findItem objMaterial.materialIDList mID

				if materialIndex > 0 then
				(

					subMaterial = objMaterial.materialList[materialIndex]

					mMergedIndex = findItem allMaterials subMaterial

					if mMergedIndex > 0 then
					(

						materialIDList[mID] = mMergedIndex

					)
					else
					(

						materialIDList[mID] = findItem allMaterials false

					)

				)
				else
				(

					materialIDList[mID] = findItem allMaterials false

				)

			)

		)
		else
		(

			-- undefined material

			fm = findItem allMaterials false

		)

		for i = 1 to n do
		(

			zface = #()

			fv = GetFace objMesh i

			fv.x += offsetVert
			fv.y += offsetVert
			fv.z += offsetVert

			if useMultiMaterial then
			(

				mID = GetFaceMatID objMesh i
				fm = materialIDList[mID]

			)

			if hasUVs then
			(

				fuv = GetTVFace objMesh i

				fuv.x += offsetUv
				fuv.y += offsetUv
				fuv.z += offsetUv

			)
			else
			(

				fuv = false

			)

			if hasVColors then
			(

				fc = GetVCFace objMesh i

				fc.x += offsetColor
				fc.y += offsetColor
				fc.z += offsetColor

			)
			else
			(

				fc = false

			)

			append zface fv
			append zface fuv
			append zface fm
			append zface fc
			append zface needsFlip

			append whereto zface
		)

	)

	-------------------------------------------------------------------------------------
	-- Extract materials from eventual multi-material

	function ExtractMaterials objMesh objMaterial whereto wheretoColors zname hasVColors =
	(

		materialClass = classof objMaterial

		if materialClass == StandardMaterial then
		(

			if ( findItem whereto objMaterial ) == 0 then
			(

				append whereto objMaterial
				append wheretoColors hasVColors

			)

		)
		else if materialClass == MultiMaterial then
		(

			n = objMesh.numFaces

			for i = 1 to n do
			(

				mID = getFaceMatId objMesh i
				materialIndex = findItem objMaterial.materialIDList mID

				if materialIndex > 0 then
				(

					subMaterial = objMaterial.materialList[materialIndex]

					if ( findItem whereto subMaterial ) == 0 then
					(

						append whereto subMaterial
						append wheretoColors hasVColors

					)

				)
			)

		)
		else
		(

			-- unknown or undefined material

			append whereto false
			append wheretoColors false

		)

	)

	-------------------------------------------------------------------------------------
	-- Hack to figure out if normals are messed up

	function NeedsFaceFlip node =
	(
		needsFlip = false

		local tmp = Snapshot node

		face_normal = normalize ( getfacenormal tmp 1 )

		face = getface tmp 1

		va = getvert tmp face[1]
		vb = getvert tmp face[2]
		vc = getvert tmp face[3]

		computed_normal = normalize ( cross (vc - vb)  (va - vb) )

		if distance computed_normal face_normal > 0.1 then needsFlip = true

		delete tmp

		return needsFlip
	)

	-------------------------------------------------------------------------------------
	-- Extract only things that either already are or can be converted to meshes

	function ExtractMesh node =
	(

		if SuperClassOf node == GeometryClass then
		(
			needsFlip = false
			hasVColors = false

			zmesh = SnapshotAsMesh node
			

			if autoflipFace.checked then
			(

				needsFlip = NeedsFaceFlip node

			)

			if exportColor.checked and ( getNumCPVVerts zmesh ) > 0 then
			(

				hasVColors = true

			)

			return #( zmesh, node.name, node.material, needsFlip, hasVColors )

		)

		-- Not geometry ... could be a camera, light, etc.

		return #( false, node.name, 0, false, false )

	)


	-------------------------------------------------------------------------------------
	-- Extract morphTargets (just more keyframed vertices) from mesh

	function ExtractMorphTargets inObjects outMorphTargets =
	(
		with animate on 
		(
		    frames = #()
		    if exportAnimateOnlyKeyframes.checked then
		    (
                -- Collect all keyframe times for all selected objects and sort them
                for obj in selection do
                (
                    keys = obj.pos.controller.keys
                    for k in keys do
                    (
						appendIfUnique frames k.time
                    )
                )
                sort frames
            )
			else 
            (
    		    -- Simply extract every frame, ignoring keyframes
                for i in animationRange.start to animationRange.end do
                    append frames i
            )
		
		    origTime = sliderTime
			for t in frames do
			(
--                if exportAnimateUpdateGui.checked then sliderTime = t
                sliderTime = t
				
				at time t
				(
					-- pks: so gross...
					tagName = undefined
					iFrame = t.frame as integer
					for i in 1 to timeTags.count do -- sorted
					(
						tt = timeTags[i]
						if(tt[1] > iFrame) then
							exit
						tagName = tt[2]
					)

				    entry = #()
					vertices = #()
					morphNormals = #()
					for obj in inObjects do
					(
						result = ExtractMesh obj
						meshObj = result[1]
						if classof meshObj != BooleanClass then
						(
							needsFlip = result[4]
--							print ("ExtractMorphTargets: " + needsFlip as string)
							if ClassOf meshObj == TriMesh then
							(
								ExtractVertices meshObj vertices
								ExtractNormals meshObj morphNormals needsFlip
							)
						)
					)
					
					append outMorphTargets #(t, tagName, vertices, morphNormals)
					
					if canceled then
						return null
				)
			)
--            if exportAnimateUpdateGui.checked then sliderTime = origTime
            sliderTime = origTime
		)
	)	
	
	
	-------------------------------------------------------------------------------------
	-- Export scene

	function ExportObjects inObjects objectName =
	(
		if (classof inObjects) != Array then
			inObjects = #(inObjects)
		
		-- Extract meshes

		meshObjects = #()
		outVertices = #()
		outNormals = #()
		outColors = #()
		outUvs = #()
		outFaces = #()
		outMaterials = #()
		outMaterialsColors = #()
		outMorphTargets = #()

		sceneHasVColors = false

		for obj in inObjects do
		(

			result = ExtractMesh obj
			meshObj = result[1]

			if ClassOf meshObj == TriMesh then
			(

				meshName     = result[2]
				meshMaterial = result[3]
				needsFlip    = result[4]
				hasVColors   = result[5]

				sceneHasVColors = sceneHasVColors or hasVColors

				append meshObjects result

				vertexOffset = outVertices.count
				uvOffset = outUvs.count
				colorOffset = outColors.count

				ExtractMaterials meshObj meshMaterial outMaterials outMaterialsColors meshName hasVColors

				ExtractVertices meshObj outVertices
				ExtractNormals meshObj outNormals needsFlip
				ExtractColors meshObj outColors

				ExtractUvs meshObj outUvs

				ExtractFaces meshObj meshMaterial outFaces outMaterials needsFlip hasVColors vertexOffset uvOffset colorOffset

				if canceled then
					exit

			)

		)

		
		if exportAnimateEnable.checked then
			ExtractMorphTargets inObjects outMorphTargets
		
		
		if not updateProgressSteps(3) then -- compile == 3 "steps"
			return null
		
		
		local package = #(meshObjects, outVertices, outNormals, outColors, outUvs, outFaces, outMaterials, outMaterialsColors, outMorphTargets)
		
		
        if OUTPUT_FORMAT == "JSON" then
		(
            JSONDumpScene package
		)
        else if OUTPUT_FORMAT == "Binary" then
        (
            exporter = BinaryExporter data:package
			exporter.WriteScene
		)
--         end

	)


	-------------------------------------------------------------------------------------
	-- Open and prepare a file handle for writing
/*
	function GetSaveFileStream =
	(
		zname = getFilenameFile maxFileName
		zname += ".js"

		fname = GetSaveFileName filename:zname types:"JavaScript file (*.js)|*.js|All Files(*.*)|*.*|"
		if fname == undefined then
		(

			return null

		)

		ostream = CreateFile fname
		if ostream == undefined then
		(

			MessageBox "Couldn't open file for writing !"
			return null

		)

		return ostream
	)
	*/
	
	function ExportAll =
    (
		-- "Time Tags" are used to name multiple animations within a single model by setting an "action" attribute in the morphTargets.
		-- JavaScript code can then use this attribute to group frames into separate animations for the same model.
		-- For example, this is useful when defining different taunts in a game character.
		timeTags = #()
		iTags = FrameTagManager.GetTagCount()
		for i in 1 to iTags do
		(
			id = FrameTagManager.GetTagID i
			n = FrameTagManager.GetNameByID id
			t = FrameTagManager.GetTimeByID id
			append timeTags #(t.frame as integer, n)
		)
		function sortTimeTags a b =
		(
			if (a[1] < b[1]) then
				return -1
			else if(a[1] > b[1]) then
				return 1
			else
				return 0
		)
		qsort timeTags sortTimeTags
		
		OUTPUT_FORMAT = outputFormats[exportFormat.state]
		
        if exportSelectAll.checked then select $*
		
		numFrames = animationRange.end - animationRange.start
		numFrames = numFrames.frame as integer

		-- compile progress data (compiling: 3, vertices: 1, morphTargets: 1n)
		numProgressTotal = 0
		for obj in selection do
		(
			numProgressStepsTotal += 3 -- compiling
			numProgressStepsTotal += 1 -- vertecies
			if exportAnimateEnable.checked then
				numProgressStepsTotal += numFrames -- morphTargets				
		)		
		progressStart ("Exporting ...")

		dirPath = getIniSetting iniPath "General" "LastSavePath"
        dirPath = getSavePath initialDir:dirPath
		if dirPath != undefined then
		(
			setIniSetting iniPath "General" "LastSavePath" dirPath
			
			if exportMergeObjects.checked then
			(
--				name = ""
--				if selection.count == 1 then
--					name = selection[1].name
				
				inObjects = #()
				for o in selection do
					append inObjects o
				filePath = dirPath + "\\" + exportMergeObjectName.text
				ExportObjects inObjects exportMergeObjectName.text
			)
			else
			(
				for obj in selection do
				(
					if classof node != Dummy then -- (classof obj == PolyMeshObject) then
					(
						filePath = dirPath + "\\" + obj.name
						ExportObjects obj obj.name
						if canceled then exit
					) 
					else
					(
						print ("Ignored " + classof obj as string)
					)
				)
			)
		)
		
		DestroyDialog ThreeJSExporter
		progressEnd()
	)

	-------------------------------------------------------------------------------------
	-- Export button click handler

	on btn_export pressed do
	(
        ExportAll()
	)
	
	on exportAnimateEnable changed x do
	(
		exportAnimateOnlyKeyframes.visible = x
	)

	on exportMergeObjects changed x do
	(
		exportMergeObjectName.visible = x --exportMergeObjects.checked
	)

	on ThreeJSExporter open do
	(
		if maxFilePath.count > 0 then -- if no file name store preferences in dir of script
			iniPath = (maxFilePath + maxFileName + ".ThreeJSExporter.ini")
		else -- if there is a max file name store prefs in same dir
			iniPath = ((getFilenamePath (getSourceFileName()) ) + "ThreeJSExporter.ini")

		for aControl in ThreeJSExporter.controls do
		(
			try
			(
				case classof aControl of
				(
					SpinnerControl: aControl.value = (readValue ((getIniSetting iniPath "Spinner" aControl.name) as stringStream))
					CheckBoxControl: aControl.state = (readValue ((getIniSetting iniPath "Checkbox" aControl.name) as stringStream))
					RadioControl: aControl.state = (readValue ((getIniSetting iniPath "RadioButton" aControl.name) as stringStream))
					SliderControl: aControl.value = (readValue ((getIniSetting iniPath "Sliders" aControl.name) as stringStream))
					EditTextControl: aControl.text = (getIniSetting iniPath "EditText" aControl.name)
				)
			) catch()
		)

		exportMergeObjectName.visible = exportMergeObjects.checked
		
		exportAnimateOnlyKeyframes.visible = exportAnimateEnable.checked
--		exportAnimateUpdateGui.visible = exportAnimateEnable.checked
	)
	
	on ThreeJSExporter close do
	(
		for aControl in ThreeJSExporter.controls do
		(
--			print (classof aControl as string)
			case classof aControl of
			(
				SpinnerControl: setIniSetting iniPath "Spinner" aControl.name (aControl.value as string)
				CheckBoxControl: setIniSetting iniPath "Checkbox" aControl.name (aControl.state as string)
				RadioControl: setIniSetting iniPath "RadioButton" aControl.name (aControl.state as string)
				SliderControl: setIniSetting iniPath "Sliders" aControl.name (aControl.value as string)				
				EditTextControl: setIniSetting iniPath "EditText" aControl.name (aControl.text as string)
			)
		)
	)

)

createDialog ThreeJSExporter width:300
