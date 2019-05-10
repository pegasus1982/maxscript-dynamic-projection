macroScript PlaceObjects
category:"Ron Tools"
tooltip:"Place Objects"
ButtonText:"Place Objects"

(

	DropPlane = undefined
	CurrentSelectedModel = undefined
	ListItems=#()
	location = undefined
	rotatelocation = undefined
	SelectedMesh = undefined
	StartRotation = undefined
	ZOffset = 0.0
	FaceNorm = undefined
	SelectedFace = undefined
	averageVertHeight = undefined
	
	rollout ObjectPlacerRO "Object Placer" width:300 height:610
	(
		
		groupbox OPGB "Options:" width:290 height:600 pos:[5,5]
		Button SelObjectsBut "Add selected objects to list" pos:[80,25]
		PickButton AddBut "Add object" pos:[20,60]
		Button DelBut "Del selected object" pos:[100,60]
		Button ClearBut "Clear List" pos:[220,60]
		Listbox lb "Items to be placed:" height:25 width:260 pos:[20,90]
		label FeedbackLbl "Idle..."
		Button StartPainting "Start placing objects" pos:[80,530] height:50 width:150 enabled:false
		checkbox RandomSelCB "Select Random Item from list" pos:[30,500] checked:true
		Edittext ZoffsetBut "Offset Z: " text:"0.0" pos:[30,470] width:100
	
	fn StopPaint =
		(
			snapMode.display = true
			snapMode.active = false
			snapMode.setOSnapItemActive 6 5 false
			snapMode.setOSnapItemActive 6 1 true
			StartPainting.enabled = true
			AddBut.enabled = true
			DelBut.enabled = true
			ClearBut.enabled = true
			SelObjectsBut.enabled = true
			
			FeedbackLbl.text = "User Canceled"
			
		)		
	
	fn ClearObject =
		(
			
			try (
				delete SelectedMesh
			)
			catch()
			
			FeedbackLbl.text = "Rotation Canceled"
			
		)
		
	fn CarPlacement MeshRot Condition =
		(
			if keyboard.controlPressed == true do (
				delete SelectedMesh
				RandomNumber = random 1 (lb.items.count)
				lb.selection = RandomNumber
				CurrentSelectedModel = lb.selected
				CopyModel = getnodebyname CurrentSelectedModel
				newNodes = #()
				maxOps.cloneNodes CopyModel cloneType:#copy newNodes:&newNodes
				SelectedMesh = newNodes[1]
				SelectedMesh.pos = location
			)
			SelectedMesh.dir = FaceNorm
			StartRotation = SelectedMesh.rotation as eulerangles
			DifferenceRot = MeshRot - location
			RotationValue = atan (DifferenceRot.x /  DifferenceRot.y)
			
			if DifferenceRot.y < 0 then (
				in coordsys local rotate SelectedMesh (angleaxis ((-RotationValue + StartRotation.z)+180) [0,0,1])
			)
			else (
				in coordsys local rotate SelectedMesh (angleaxis ((((-RotationValue)+(180)) + StartRotation.z)+ 180) [0,0,1])
			)
			
			if Condition == true do (
			FeedbackLbl.text = CurrentSelectedModel + " placed!"
			)
		
		)
		
					
	fn getViewDirectionRay =
	(
		local coordSysTM = Inverse(getViewTM())
		local viewDir = -coordSysTM.row3
		return viewDir
	)
	
	fn PlaceObject =
		(
			Dropplane = boxPickNode (box2 (mouse.pos - [0.01,0.01]) (mouse.pos + [0.01,0.01]))
			CurrentSelectedModel = lb.selected
			CopyModel = getnodebyname CurrentSelectedModel
			newNodes = #()
			maxOps.cloneNodes CopyModel cloneType:#copy newNodes:&newNodes
			SelectedMesh = newNodes[1]
			SelectedMesh.rotation = (quat 0 0 0 1)
			
			pos = [location.x,location.y,(location.z + 0.0)]
			
			try (
				ConvertTo Dropplane[Dropplane.count] Editable_Mesh
				
				rm = RayMeshGridIntersect ()
				rm.Initialize 1
				rm.addNode Dropplane[Dropplane.count]
				rm.buildGrid ()
				
				ViewDirection = getViewDirectionRay()
				theHitsCount = rm.intersectRay [pos.x,pos.y,pos.z + 0.5] ViewDirection true
				if theHitsCount > 0 then
				(
				theFace = rm.getHitFace 1
				FaceNorm = getfacenormal Dropplane[Dropplane.count] theFace
				)
				
				else (
					ViewDirection = getViewDirectionRay()
					theHitsCount = rm.intersectRay [pos.x,pos.y,pos.z + 0.5] -ViewDirection true
					if theHitsCount > 0 then
					(
						theFace = rm.getHitFace 1
						FaceNorm = getfacenormal Dropplane[Dropplane.count] theFace
					)
					else (
					FaceNorm = [0,0,1]
					)
				)
					
				)
				
			catch (
				FaceNorm = [0,0,1]
				)
			
			SelectedMesh.dir = FaceNorm
			
			ViewDirection = getViewDirectionRay()
			MeshRay = ray [pos.x,pos.y,pos.z + 0.01] ViewDirection
			if DropPlane != undefined and DropPlane.count != 0 then
				(
					rayCastResult = intersectRay DropPlane[Dropplane.count] MeshRay
					if rayCastResult != undefined then
					(
						location = [location.x,location.y,rayCastResult.pos.z]
					)
					
					else (
						ViewDirection = getViewDirectionRay()
						MeshRay = ray [pos.x,pos.y,pos.z + 0.01] -ViewDirection
						rayCastResult = intersectRay DropPlane[Dropplane.count] MeshRay
						if rayCastResult != undefined then (
							location = [location.x,location.y,rayCastResult.pos.z]
						)
						else (
							location = [location.x,location.y,0]
						)
					)
				)
			else (
				location = [location.x,location.y,0]
			)
			
			location = location + [0,0,ZOffset]
			
			SelectedMesh.pos =  location
			StartRotation = SelectedMesh.rotation
			
			rotatelocation = pickpoint snap:#3d rubberBand:location mouseMoveCallback:#(CarPlacement,false)
			
				case of
				(
					(rotatelocation == undefined): #stop 
					(rotatelocation == #rightClick): ClearObject()
					(classOf rotatelocation == Point3): CarPlacement rotatelocation true
					(classOf rotatelocation == String): #stop
				)
			
		)
		
	on ZoffsetBut changed txt do(
	
		finalstring = ""
		filteredstring = filterString txt "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,/;'[]\=<>?:{}|+_`~!@#$%^&*()"
		for i=1 to filteredstring.count do(
			finalstring = finalstring + (filteredstring[i] as string)
		)
		if finalstring == undefined do(
			finalstring = ""
		)
		
		if finalstring != "" do (
			try (
			ZOffset = finalstring as float
			ZoffsetBut.text = finalstring as string
			)
			catch( 
				ZOffset = 0.0 
				ZoffsetBut.text = "0.0"
			)
			
		)
	
	)
			
	on StartPainting pressed do(
			snapMode.display = false
			snapMode.active = true
			--snapMode.setOSnapItemActive 6 5 true
			--snapMode.setOSnapItemActive 6 1 false
			StartPainting.enabled = false
			AddBut.enabled = false
			DelBut.enabled = false
			ClearBut.enabled = false
			SelObjectsBut.enabled = false
			
			FeedBackLbl.text = "Click to place object"
			
			while StartPainting.enabled == false do(
				if RandomSelCB.state == true do (
					RandomNumber = random 1 (lb.items.count)
					lb.selection = RandomNumber
				)
				CurrentSelectedModel = lb.selected
					
				location = pickpoint snap:#3d
					
				case of
				(
					(location == undefined): #stop 
					(location == #rightClick): StopPaint()
					(classOf location == Point3): PlaceObject()
					(classOf location == String): #stop
				)
			)
			
		)
		
		on ClearBut pressed do (
			
			FeedbackLbl.text = lb.items.count as string + " item(s) deleted!"
			ListItems=#()
			lb.items = ListItems
			StartPainting.enabled = false
			
		)
		
		on SelObjectsBut pressed do (
			
			InitSelection = selection
			if InitSelection.count > 0 do (
				
				counter = 0
				
				for i=1 to InitSelection.count do (
					
					UniqueChecker = appendifunique ListItems InitSelection[i].name
					if UniqueChecker == true do (
						counter+= 1
					)
					
				)
				
				lb.items = ListItems
				FeedbackLbl.text = counter as string + " item(s) added!"
				if ListItems.count != 0 do (
					StartPainting.enabled = true
				)
				
			)
			
		)
		
		on DelBut pressed do (
			
			CurSelection = lb.selected
			if CurSelection != undefined do (
				deleteitem ListItems (finditem ListItems CurSelection)
				lb.items = ListItems
				FeedbackLbl.text = CurSelection + " succesfully deleted!"
				if ListItems.count == 0 do (
					StartPainting.enabled = false
				)
				return()
			)
			FeedbackLbl.text = "No item selected!"
		)
		
		on AddBut picked obj do (
			
			if obj != undefined do (
				UniqueChecker = appendifunique ListItems obj.name
				if UniqueChecker == true then (
					StartPainting.enabled = true
					FeedbackLbl.text = (obj.name + " added!")
					lb.items = ListItems
				)
				else (
					FeedbackLbl.text = "Object already in list!"
				)
			)
			
		)
		
	)
	
	createdialog ObjectPlacerRO () pos:[10,90] 
	
)