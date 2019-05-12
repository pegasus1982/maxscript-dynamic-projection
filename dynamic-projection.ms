rollout DynamicProjection "Dynamic Projection"
(
    -- rollout ui
    editText edit_FilePath   "File Name" pos:[17,  15] width:275
    button   btn_Browse      "Browse..." pos:[302, 13]
    spinner  spin_Radius     "Radius"    pos:[40,  45] width:70  type:#integer range:[20,600,100]
    checkbox check_spherical "Spherical Projection" pos:[117, 45]
    checkButton   btn_Left   "Left"      pos:[235, 42] width:60
    checkButton   btn_Right  "Right"     pos:[305, 42] width:60
    button   btn_Export      "Export"    pos:[375, 13] width:110 height:50
    -- end rollout ui

    local originLeftPointArray = #()
    local originRightPointArray = #()
    local color_pink = (color 255 23 215)
    local color_cyan = (color 23 255 215)

    global leftCollectionController
    global rightCollectionController

    global leftCollectionPointsOffset
    global rightCollectionPointsOffset

    global leftProjectionType --false:planar, true:spherical
    global rightProjectionType --false:planar, true:spherical

    global object_to_align
    global surface_obj
    global original_TM

    -- read data from csv
    fn readDataFile path = (
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

            -- reset offset array
            if type == "left" then(
                leftCollectionPointsOffset = #()
            )
            else(

            )
            -- end reset offset array

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
                    in coordsys #local sph.pos.z += 3

                    if type == "left" then(
                        tmp_arr = [(centerX-arr[i][2])*t, (centerY-arr[i][3])*t]
                        append leftCollectionPointsOffset tmp_arr
                    )
                    else(

                    )
                    
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
        -- set freeze
        when select object_to_align changes do(
            deselect $*_collection_controller_panel*
        )
        -- end set freeze

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
        -- set freeze
        when select axis changes do(
            deselect $*_collection_controller_axis*
        )
        -- end set freeze
        
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
        -- set freeze
        when select axisCone changes do(
            deselect $*_collection_controller_axis_cone*
        )
        -- end set freeze

        diameter = Cylinder()
        diameter.radius = 0.3
        diameter.height = object_to_align.radius
        diameter.name = (type+"_collection_controller_diameter")
        diameter.pos = object_to_align.pos
        diameter.pivot = object_to_align.pos
        diameter.dir = object_to_align.dir
        diameter.transform = (rotateYmatrix 90) * diameter.transform
        diameter.wirecolor = clr
        -- set freeze
        when select diameter changes do(
            deselect $*_collection_controller_diameter*
        )
        -- end set freeze
        
        rotate_handle = sphere()
        rotate_handle.radius = 1.6
        rotate_handle.name = (type+"_collection_controller_rotate_handle")
        rotate_handle.pos = object_to_align.pos
        rotate_handle.dir = object_to_align.dir
        in coordsys #local rotate_handle.pos.x += object_to_align.radius
        rotate_handle.pivot = object_to_align.pos
        rotate_handle.wirecolor = clr
        -- set freeze
        when select rotate_handle changes do(
            deselect $*_collection_controller_rotate_handle*
        )
        -- end set freeze

        object_to_align.parent = center
        diameter.parent = center
        rotate_handle.parent = center
        axis.parent = center
        axisCone.parent = center
        in coordsys #local center.pos.z += 3

        return center
    )

    fn findPlanarIntersection s = (
        testRay = ray s.pos (s.dir*[-1,-1,-1])
        intersectRay surface_obj testRay
    )

    fn findSphericalIntersection s s_offset = (
        local posCenter = s.parent.pos
        local posCurrent = s.pos
        local radius = distance posCenter posCurrent
        -- create circle
        local tmp_name = s.name+"_circle_ray"
        cir = getNodeByName tmp_name
        if cir == undefined then(
            cir = circle()
            cir.ishidden = true
            cir.name = tmp_name
            cir.parent = s.parent
            cir.radius = radius
            cir.pos = posCenter
            cir.dir = s.parent.dir
            local d_gamma = atan(s_offset[1]/(s_offset[2] as float))
            in coordsys #local rotate cir (eulerangles 0 90 -d_gamma)

            --divide circle to sub segment
            local div = 5
            convertToSplineShape cir
            for i=1 to (numsplines cir) do
            (
                for j=(numSegments cir i) to 1 by-1 do
                subdividesegment cir i j div
            )
            updateshape cir
            -- end divide circle
        )
        -- scale circle
        local rate = (spin_Radius.value as float)/100
        -- end scale circle
        -- get vertex from circle
        local cir_points = #()
        for s = 1 to (numsplines cir) do(
            for k = 1 to (numknots cir s) do (
                local p = getKnotPoint cir s k
                local d_offset = p-posCenter
                p = posCenter+d_offset*rate
                append cir_points p
            )
        )
        -- end get vertex from circle

        -- get intersection points
        local p_intersections = #()
        for i = 1 to (cir_points.count-1) do (
            local pA = cir_points[i]
            local pB = cir_points[i+1]

            --check positive direction
            --configurate ray
            local n = normalize (pB-pA)
            local testray = ray pA n
            --end configrate ray
            local i = intersectRay surface_obj testRay
            if (i != undefined) do(
                append p_intersections i.pos
            )
            --end check positive direction
            --check negative direction
            --configurate ray
            n = normalize (pA-pB)
            testray = ray pB n
            --end configrate ray
            i = intersectRay surface_obj testRay
            if (i != undefined) do(
                append p_intersections i.pos
            )
            --end check negative direction
        )
        -- end get intersection points

        -- check intersection points
        -- format "radius %\n" radius
        local limit = 2
        local arr_candidates = #()
        for i = 1 to p_intersections.count do(
            p_candidate = p_intersections[i]
            -- check distance from center
            dis = distance posCenter p_candidate
            if (abs(radius-dis)<limit) do(
                append arr_candidates p_candidate
            )
            -- end check distance from center
        )
        local min_dis = radius
        local finalIndex = 1
        for i=1 to arr_candidates.count do(
            dis = distance arr_candidates[i] posCurrent
            if(dis < min_dis) do(
                min_dis = dis
                finalIndex = i
            )
        )
        -- format "index : %, pos : %\n" finalIndex arr_candidates[finalIndex]
        -- end check intersection points
        return arr_candidates[finalIndex]
    )
    -- update planar projection points
    fn updatePlanarProjectionPoints points clr = (
        if points != undefined do(
            res = #()
            for i = 1 to points.count do(
                p = points[i]
                in coordsys #local p.pos.z += 200
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

                int_point = findPlanarIntersection p
                if int_point != undefined then pro.pos = int_point.pos
                append res pro
            )
            return res
        )
    )
    -- end update planar projection points
    -- update spherical projection points
    fn updateSphericalProjectionPoints points clr = (
        -- print "spherical projection"
        if points != undefined do(
            res = #()
            for i = 1 to points.count do( --points.count
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

                int_point = findSphericalIntersection p leftCollectionPointsOffset[i]
                if int_point != undefined then pro.pos = int_point
                append res pro
            )
            return res
        )
    )
    -- end update spherical projection points

    -- redraw points
    fn updatePointsBySpin = (
        -- for left point collection
        if (isValidNode leftCollectionController)  do(
            newPoints = drawPoints leftCollectionController "left"
            for i = 1 to newPoints.count do(
                newPoints[i].parent = leftCollectionController
            )

            if(leftProjectionType == false) then(
                projections = updatePlanarProjectionPoints newPoints color_pink
                for i = 1 to projections.count do(
                    projections[i].parent = leftCollectionController
                )
            )
            else(
                projections = updateSphericalProjectionPoints newPoints color_pink
                for i = 1 to projections.count do(
                    projections[i].parent = leftCollectionController
                )
            )
        )
        -- end for left point collection

        -- for right point collection
        if (isValidNode rightCollectionController) do(
            newPoints = drawPoints rightCollectionController "right"
            for i = 1 to newPoints.count do(
                newPoints[i].parent = rightCollectionController
            )
            if(rightProjectionType == false) then(
                projections = updatePlanarProjectionPoints newPoints color_cyan
                for i = 1 to projections.count do(
                    projections[i].parent = rightCollectionController
                )
            )
            else(
                projections = updateSphericalProjectionPoints newPoints color_cyan
                for i = 1 to projections.count do(
                    projections[i].parent = rightCollectionController
                )
            )
        )
        -- end for right point collection
    )
    -- end redraw points

    -- create point collection
    fn createCollection = (
        if btn_Left.checked == true then (
            btn_Left.checked = false

            leftCollectionController = createController "left"
            points = drawPoints leftCollectionController "left"
            for i = 1 to points.count do(
                points[i].parent = leftCollectionController
                points[i].ishidden = true
            )
            
            -- get projection
            -- get planar projection
            leftProjectionType = check_spherical.checked
            
            local projections
            if check_spherical.checked == false then(
                projections = updatePlanarProjectionPoints points color_pink
                for i = 1 to projections.count do(
                    projections[i].parent = leftCollectionController
                )
            )
            -- get spherical projection
            else(
                projections = updateSphericalProjectionPoints points color_pink
                for i = 1 to projections.count do(
                    projections[i].parent = leftCollectionController
                )
            )
            -- end get projection

            -- set freeze
            when select $*_projection* changes do(
                deselect $*_projection*
            )
            -- end set freeze

            when select leftCollectionController changes do(
                check_spherical.checked=leftProjectionType
            )
            -- rotate event
            when transform leftCollectionController changes do(
                local points = #()
                for i = 1 to originLeftPointArray.count do(
                    index = originLeftPointArray[i][1] as string
                    tmp_name = "left_point_"+index
                    obj = getNodeByName tmp_name
                    append points obj
                )
                if(leftProjectionType == false) then(
                    local projections = updatePlanarProjectionPoints points color_pink
                    for i = 1 to projections.count do(
                        projections[i].parent = leftCollectionController
                    )
                )
                else(
                    projections = updateSphericalProjectionPoints points color_pink
                    for i = 1 to projections.count do(
                        projections[i].parent = leftCollectionController
                    )
                )
            )
            -- end rotate event
        )
        else(
            btn_Right.checked = false

            rightCollectionController = createController "right"

            points = drawPoints rightCollectionController "right"
            for i = 1 to points.count do(
                points[i].parent = rightCollectionController
            )
            rightProjectionType = check_spherical.checked
            local projections
            if check_spherical.checked == false then(
                projections = updatePlanarProjectionPoints points color_cyan
                for i = 1 to projections.count do(
                    projections[i].parent = rightCollectionController
                )
            )
            else(
                projections = updateSphericalProjectionPoints points color_cyan
                for i = 1 to projections.count do(
                    projections[i].parent = rightCollectionController
                )
            )

            -- set freeze
            when select $*_projection* changes do(
                deselect $*_projection*
            )
            -- end set freeze

            when select rightCollectionController changes do(
                check_spherical.checked=rightProjectionType
            )

            -- rotate event
            when transform rightCollectionController changes do(
                local points = #()
                for i = 1 to originRightPointArray.count do(
                    index = originRightPointArray[i][1] as string
                    tmp_name = "right_point_"+index
                    obj = getNodeByName tmp_name
                    append points obj
                )
                if(rightProjectionType == false) then(
                    local projections = updatePlanarProjectionPoints points color_cyan
                    for i = 1 to projections.count do(
                        projections[i].parent = rightCollectionController
                    )
                )
                else(
                    local projections = updateSphericalProjectionPoints points color_cyan
                    for i = 1 to projections.count do(
                        projections[i].parent = rightCollectionController
                    )
                )
            )
            -- end rotate event
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
            btn_Left.checked = false
            btn_Right.checked = false
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
            readDataFile dlg.fileName
        )
    )
    -- end open file dialog

    -- left button event
    on btn_Left changed state do (
        btn_Right.checked = false
        if state == true do(
            try(
                delete $*left_collection_controller*
                delete $*left_point*
                delete $*Circle*

                object_to_align = Cylinder()
                object_to_align.radius = 30
                object_to_align.height = 0.5
                object_to_align.name = "left_collection_controller_panel"

                surface_obj = pickobject prompt:"Pick surface to move to."
                original_TM = object_to_align.transform
                a = mouseTrack on:surface_obj trackCallback:assign_normal
            )catch(
                btn_Left.checked = false
            )
        )
    )
    -- end left button event

    -- right button event
    on btn_Right changed state do(
        btn_Left.checked = false
        if state == true do(
            try(
                delete $*right_collection_controller*
                delete $*right_point*
                object_to_align = Cylinder()
                object_to_align.radius = 30
                object_to_align.height = 0.5
                object_to_align.name = "right_collection_controller_panel"

                surface_obj = pickobject prompt:"Pick surface to move to."
                original_TM = object_to_align.transform
                a = mouseTrack on:surface_obj trackCallback:assign_normal
            )catch(
                btn_Right.checked = false
            )
        )
    )
    -- end right button event

    -- spinner event
    on spin_Radius changed newValue do (
        updatePointsBySpin()
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
        -- print "left"
        -- print leftPositionProjected
        -- print "right"
        -- print rightPositionProjected

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