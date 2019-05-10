rollout DynamicProjection "Dynamic Projection"
(
    -- rollout ui
	editText edit_FilePath   "File Name" pos:[20,  15] width:250
	button   btn_Browse      "Browse..." pos:[287, 13]
    spinner  spin_Radius     "Radius"    pos:[43,  45] width:70  type:#integer range:[20,600,100] 
    checkButton   btn_Left   "Left"      pos:[220, 42] width:60
	checkButton   btn_Right  "Right"     pos:[290, 42] width:60
	button   btn_Export      "Export"    pos:[370, 13] width:110 height:50
    -- end rollout ui

    local originLeftPointArray = #()
    local originRightPointArray = #()
    local color_pink = (color 255 23 215)
    local color_cyan = (color 23 255 215)

    global leftCollectionController
    global rightCollectionController

    global object_to_align
    global surface_obj
    global original_TM

    -- read data from csv
    fn readFile path = (
        AssyFile = openfile path
        if (AssyFile != undefined) then
        (
            skiptonextline AssyFile
            while not eof AssyFile do(
                str = readline AssyFile
                if str == ",,,,,,,,,,,," or str == "" do(continue)
                newStr = filterstring str "," splitEmptyTokens:true
                
                rightID = newStr[1] as Integer
                rightX  = newStr[2] as float
                rightY  = newStr[3] as float--format "right -> id : % , x : % , y : %\n" rightID rightX rightY

                leftID  = newStr[8] as Integer
                leftX   = newStr[9] as float
                leftY   = newStr[10] as float
                --format "left ->  id : % , x : % , y : %\n" leftID leftX leftY

                newLeftArrayItem = #(leftID, leftX, leftY)
                newRightArrayItem = #(rightID, rightX, rightY)
                
                append originLeftPointArray newLeftArrayItem
                append originRightPointArray newRightArrayItem
            )
        )
        else( messageBox "Open Failed" title:"Error!" )
    )
    -- end read data from csv
    
    -- create points collection
    fn drawPoints parent type = (
        local arr
        local p_color
        if type == "left" then (
            arr = originLeftPointArray
            p_color = color_pink
        )
        else (
            arr = originRightPointArray
            p_color = color_cyan
        )
        if(arr.count > 0) do(
            res = #()
            ID   = arr[1][1]
            minX = arr[1][2]
            minY = arr[1][3]
            maxX = arr[1][2]
            maxY = arr[1][3]
            for i = 2 to arr.count do(
                if(minX > arr[i][2]) do(minX = arr[i][2])
                if(minY > arr[i][3]) do(minY = arr[i][3])
                if(maxX < arr[i][2]) do(maxX = arr[i][2])
                if(maxY < arr[i][3]) do(maxY = arr[i][3])
            )
            bounce = spin_Radius.value
            t = 0
            centerX = (maxX + minX) / 2
            centerY = (maxY + minY) / 2
            if((maxX-minX) > (maxY-minY)) then(
                t = bounce / float(maxX-minX)
            )
            else(
                t = bounce / float(maxY-minY)
            )
            for i = 1 to arr.count do(
                index = arr[i][1] as string
                tmp_name = type+"_point_"+index
                try(
                    sph = getNodeByName tmp_name
                    if sph == undefined then(
                        sph = sphere()
                        sph.name = tmp_name
                        sph.wirecolor = p_color
                        sph.radius = 1
                    )
                    
                    sph.pos = parent.pos
                    sph.dir = parent.dir
                    in coordsys #local sph.pos.x += (centerX-arr[i][2])*t
                    in coordsys #local sph.pos.y += (centerY-arr[i][3])*t
                    in coordsys #local sph.pos.z += 200
                    
                    append res sph
                )
                catch()
            )
            return res
        )
    )

    fn createController type = (
        local clr
        if type == "left" then(clr = color_pink) else(clr = color_cyan)
        object_to_align.material = StandardMaterial diffuse:clr opacity:30 name:("mat_controller_opacity")
        when select object_to_align changes do(
 			deselect $*_collection_controller_panel*
 		)

        center = box()
        center.length = 6
        center.width = 6
        center.height = 6
        center.name = (type+"_collection_controller_center")
        center.pos = object_to_align.pos
        center.dir = object_to_align.dir
        in coordsys #local center.pos.z -= 3
        center.wirecolor = clr

        axis = Cylinder()
        axis.radius = 0.3
        axis.height = 30
        axis.pos = object_to_align.pos
        axis.dir = object_to_align.dir
        axis.name = (type+"_collection_controller_axis")
        axis.wirecolor = clr
        when select axis changes do(
 			deselect $*_collection_controller_axis*
 		)
        
        axisCone = cone()
        axisCone.radius1 = 1.3
        axisCone.radius2 = 0
        axisCone.height = 4
        axisCone.heightsegs = 1
        axisCone.pos = object_to_align.pos
        axisCone.dir = object_to_align.dir
        axisCone.name = (type+"_collection_controller_axis_cone")
        axisCone.wirecolor = clr
        in coordsys #local axisCone.pos.z += 30
        when select axisCone changes do(
 			deselect $*_collection_controller_axis_cone*
 		)

        diameter = Cylinder()
        diameter.radius = 0.3
        diameter.height = object_to_align.radius
        diameter.name = (type+"_collection_controller_diameter")
        diameter.pos = object_to_align.pos
        diameter.pivot = object_to_align.pos
        diameter.dir = object_to_align.dir
        diameter.transform = (rotateYmatrix 90) * diameter.transform
        diameter.wirecolor = clr
        when select diameter changes do(
 			deselect $*_collection_controller_diameter*
 		)
        
        rotate_handle = sphere()
        rotate_handle.radius = 1.6
        rotate_handle.name = (type+"_collection_controller_rotate_handle")
        rotate_handle.pos = object_to_align.pos
        rotate_handle.dir = object_to_align.dir
        in coordsys #local rotate_handle.pos.x += object_to_align.radius
        rotate_handle.pivot = object_to_align.pos
        rotate_handle.wirecolor = clr
        when select rotate_handle changes do(
 			deselect $*_collection_controller_rotate_handle*
 		)

        object_to_align.parent = center
        diameter.parent = rotate_handle
        rotate_handle.parent = center
        axis.parent = center
        axisCone.parent = center
        in coordsys #local center.pos.z += 3

        return center
    )

    fn find_intersection s =(
        testRay = ray s.pos (s.dir*[-1,-1,-1])
        intersectRay surface_obj testRay
    )

    fn updateProjectionPoints points clr = (
        if points != undefined do(
            res = #()
            for i = 1 to points.count do(
                p = points[i]
                p.ishidden=true
                tmp_name = (p.name+"_projection")
                pro = getNodeByName tmp_name
                if pro == undefined then(
                    pro = sphere()
                    pro.name = tmp_name
                    pro.radius = p.radius
                    pro.pos = p.pos
                    pro.wirecolor = clr
                )

                int_point = find_intersection p
                if int_point != undefined then pro.pos = int_point.pos
                append res pro
            )
            return res
        )
    )

    -- redraw points
    fn updatePoints = (
        -- for left point collection
        if (isValidNode leftCollectionController)  do(
            newPoints = drawPoints leftCollectionController "left"
            for i = 1 to newPoints.count do(
                newPoints[i].parent = leftCollectionController
            )

            projections = updateProjectionPoints newPoints color_pink
            for i = 1 to projections.count do(
                projections[i].parent = leftCollectionController
            )
        )
        -- end for left point collection

        -- for right point collection
        if (isValidNode rightCollectionController) do(
            newPoints = drawPoints rightCollectionController "right"
            for i = 1 to newPoints.count do(
                newPoints[i].parent = rightCollectionController
            )

            projections = updateProjectionPoints newPoints color_cyan
            for i = 1 to projections.count do(
                projections[i].parent = rightCollectionController
            )
        )
        -- end for right point collection
    )
    -- end redraw points

    fn createCollection = (
        if btn_Left.checked == true then (
            btn_Left.checked = false

            leftCollectionController = createController "left"
            points = drawPoints leftCollectionController "left"
            for i = 1 to points.count do(
                points[i].parent = leftCollectionController
            )
            
            projections = updateProjectionPoints points color_pink
            for i = 1 to projections.count do(
                projections[i].parent = leftCollectionController
            )
            when select $*_projection* changes do(
                deselect $*_projection*
            )
            when transform leftCollectionController changes do(
                local points = #()
                for i = 1 to originLeftPointArray.count do(
                    index = originLeftPointArray[i][1] as string
                    tmp_name = "left_point_"+index
                    obj = getNodeByName tmp_name
                    append points obj
                )
                local projections = updateProjectionPoints points color_pink
                for i = 1 to projections.count do(
                    projections[i].parent = leftCollectionController
                )
            )
        )
        else(
            btn_Right.checked = false

            rightCollectionController = createController "right"

            points = drawPoints rightCollectionController "right"
            for i = 1 to points.count do(
                points[i].parent = rightCollectionController
            )
            
            projections = updateProjectionPoints points color_cyan
            for i = 1 to projections.count do(
                projections[i].parent = rightCollectionController
            )
            when transform rightCollectionController changes do(
                local points = #()
                for i = 1 to originRightPointArray.count do(
                    index = originRightPointArray[i][1] as string
                    tmp_name = "right_point_"+index
                    obj = getNodeByName tmp_name
                    append points obj
                )
                local projections = updateProjectionPoints points color_cyan
                for i = 1 to projections.count do(
                    projections[i].parent = rightCollectionController
                )
            )
        )
    )
    -- end create point collection

    -- assign controller to surface
    fn assign_normal msg ir obj faceNum shift ctrl alt = (
        if msg == #freeMove then (
            if ir != undefined then (
                object_to_align.pos = ir.pos 
                object_to_align.dir = ir.dir
                return #continue
            )
            else(
                return #continue
            )
        )
        if msg == #mouseAbort then (
            delete $*left_collection_controller*
            return #end
        )
        if msg != #mousePoint then (
            return #continue
        )
        else (
            createCollection()
            return #end
        )
    )
    -- end assign controller to surface

    -- event listeners
    -- open file dialog
    on btn_Browse pressed do (
        dlg = dotNetObject "System.Windows.Forms.OpenFileDialog"
        dlg.title = "Please select a CSV file to get point data"
        dlg.Multiselect = false
        dlg.Filter = "CSV files (*.csv)|*.csv|All Files (*.*)|*.*"
        result = dlg.showDialog()
        if(result.Equals result.OK) do(
            edit_FilePath.text = dlg.fileName
            readFile dlg.fileName
        )
    )
    -- end open file dialog

    -- left button event
    on btn_Left changed state do (
        btn_Right.checked = false
        if state == true do(
            delete $*left_collection_controller*
            delete $*left_point*

            object_to_align = Cylinder()
            object_to_align.radius = 30
            object_to_align.height = 0.5
            object_to_align.name = "left_collection_controller_panel"

            surface_obj = pickobject prompt:"Pick surface to move to."
            original_TM = object_to_align.transform
            a = mouseTrack on:surface_obj trackCallback:assign_normal
        )
    )
    -- end left button event

    -- right button event
    on btn_Right changed state do(
        btn_Left.checked = false
        if state == true do(
            delete $*right_collection_controller*
            delete $*right_point*
            object_to_align = Cylinder()
            object_to_align.radius = 30
            object_to_align.height = 0.5
            object_to_align.name = "right_collection_controller_panel"

            surface_obj = pickobject prompt:"Pick surface to move to."
            original_TM = object_to_align.transform
            a = mouseTrack on:surface_obj trackCallback:assign_normal
        )
    )
    -- end right button event

    -- spinner event
    on spin_Radius changed newValue do (
        updatePoints()
    )
    -- end spinner event
    -- export button event
    on btn_Export pressed do(
        -- get left position projected to surface
        local leftPoints = $*left_point_*_projection* as array
        local leftPositionProjected = #()
        for i = 1 to leftPoints.count do(
            a = leftPoints[i]
            if(isValidNode a) do(
                str = a.name
                newStr = filterstring str "_" splitEmptyTokens:true
                id = newStr[3]
                x = a.pos.x
                y = a.pos.y
                z = a.pos.z
                local info = #(id,x,y,z)
                append leftPositionProjected info
            )
        )
        -- end get left position projected to surface

        -- get right position projected to surface
        local rightPoints = $*right_point_*_projection* as array
        local rightPositionProjected = #()
        for i = 1 to rightPoints.count do(
            a = rightPoints[i]
            if(isValidNode a) do(
                str = a.name
                newStr = filterstring str "_" splitEmptyTokens:true
                id = newStr[3]
                x = a.pos.x
                y = a.pos.y
                z = a.pos.z
                local info = #(id,x,y,z)
                append rightPositionProjected info
            )
        )
        -- end get right position projected to surface
        print "left"
        print leftPositionProjected
        print "right"
        print rightPositionProjected

        -- open file
        folder = getFilenamePath edit_FilePath.text
        local outputFilePath
        if(isValidNode surface_obj) then(
            outputFilePath = (folder+surface_obj.name+".csv")
        )
        else(
            outputFilePath = (folder+"output.csv")
        )
        try(
            out_file = createFile outputFilePath
            format "RightID, Right x, Right y, Right z, LeftID, Left x, Left y, Left z\n" to:out_file
            -- end open file
            cnt = 0
            if(leftPositionProjected.count > rightPositionProjected.count) then(cnt=leftPositionProjected.count) else(cnt=rightPositionProjected.count)
            for i = 1 to cnt do(
                if i <= rightPositionProjected.count then(
                    format "%, %, %, %, " rightPositionProjected[i][1] rightPositionProjected[i][2] rightPositionProjected[i][3] rightPositionProjected[i][4] to:out_file
                )
                else(format ", , , , " to:out_file)
                if i <= leftPositionProjected.count then(
                    format "%, %, %, %\n" leftPositionProjected[i][1] leftPositionProjected[i][2] leftPositionProjected[i][3] leftPositionProjected[i][4] to:out_file
                )
                else(format ", , ,\n" to:out_file)
            )
            -- write coord data
            close out_file
            messageBox "Exporting Result Successed" title:"Info!"
        )
        catch(
            messageBox "Can't Create Output File" title:"Error!"
        )
    )
    -- end export button event
    -- end event listeners
)

createdialog DynamicProjection width:500 height:75