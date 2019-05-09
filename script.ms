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
    local targetMesh

    -- read data from csv
    fn readFile path = (
        print "read csv file"
        AssyFile = openfile path
        if (AssyFile != undefined) then
        (
            skiptonextline AssyFile
            while not eof AssyFile do(
                str = readline AssyFile
                if str == ",,,,,,,,,,,," or str == "" do(continue)
                newStr = filterstring str "," splitEmptyToken:false
                
                rightID = newStr[1] as Integer
                rightX  = newStr[2] as float
                rightY  = newStr[3] as float--format "right -> id : % , x : % , y : %\n" rightID rightX rightY

                leftID  = newStr[7] as Integer
                leftX   = newStr[8] as float
                leftY   = newStr[9] as float
                --format "left ->  id : % , x : % , y : %\n" leftID leftX leftY

                newLeftArrayItem = #(leftID, leftX, leftY)
                newRightArrayItem = #(rightID, rightX, rightY)
                
                append originLeftPointArray newLeftArrayItem
                append originRightPointArray newRightArrayItem
            )
            --print "left point array"
            --print originLeftPointArray
            --print "right point array"
            --print originRightPointArray
        )
        else( messageBox "Open Failed" title:"Error!" )
    )
    -- end read data from csv
    
    -- find intersection
    fn find_intersection node_to_z =(
        local testRay = ray node_to_z.pos [0,0,-1]
        local nodeMaxZ = targetMesh.max.z
        testRay.pos.z = nodeMaxZ + 0.0001 * abs nodeMaxZ
        intersectRay targetMesh testRay
    )
    -- end find intersection
    -- drawing points
    fn createSpheresFromArray arr p p_name p_color = (
        if(arr.count > 0) do(
            ID   = arr[1][1]
            minX = arr[1][2]
            minY = arr[1][3]
            maxX = arr[1][2]
            maxY = arr[1][3]
            for i = 2 to arr.count do(
                format "x : %, y : %\n" arr[i][1] arr[i][2]
                if(minX > arr[i][1]) do(minX = arr[i][2])
                if(minY > arr[i][2]) do(minY = arr[i][3])
                if(maxX < arr[i][1]) do(maxX = arr[i][2])
                if(maxY < arr[i][2]) do(maxY = arr[i][3])
            )
            bounce = spin_Radius.value
            t = 0
            format "min x : %, max x : %\n" minX maxX
            format "min y : %, max y : %\n" minY maxY
            centerX = (maxX + minX) / 2
            centerY = (maxY + minY) / 2
            print (maxX-minX)
            print (maxY-minY)
            if((maxX-minX) > (maxY-minY)) then(
                t = bounce / float(maxX-minX)
            )
            else(
                t = bounce / float(maxY-minY)
            )
            format "bounce : %, t : %\n" bounce t
            for i = 1 to arr.count do(
                sph = sphere()
                sph.name = p_name
                sph.wirecolor = p_color
                sph.radius = 1
                sph.position.x = p[1]-(centerX-arr[i][2])*t
                sph.position.y = p[2]-(centerY-arr[i][3])*t
                sph.position.z = p[3]
                
                -- find intersection
                int_point = find_intersection sph
                if int_point != undefined then sph.pos = int_point.pos
            )
        )
    )
    fn drawPoints p btn = (
        btn_Left.checked = false
        btn_Right.checked = false

        if(classOf p == Point3) do(
            if(btn == "left") then(
                delete $*left_point*
                arr = originLeftPointArray
                createSpheresFromArray arr p "left_point" color_pink
            )
            else(
                delete $*right_point*
                arr = originLeftPointArray
                createSpheresFromArray arr p "right_point" color_cyan
            )
        )
    )
    -- end drawing points

    -- event listeners
    -- open file dialog
    on btn_Browse pressed do
    (
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
    on btn_Left changed state do(
        btn_Right.checked = false
        if state == true do(
            p = pickobject prompt:"Pick surface to move to."
            targetMesh = p
            try(
                mouseray = mapScreenToWorldRay mouse.pos
                sectray = intersectRayEx $ mouseray
                Intersectpos = sectray[1].pos
                print "get"
                drawPoints Intersectpos "left"
            )catch(
                print "default"
                Intersectpos = gw.mapCPToWorld (gw.getPointOnCP mouse.pos)
                --drawPoints Intersectpos "left"
            )
        )
    )
    -- end left button event

    -- right button event
    on btn_Right changed state do(
        btn_Left.checked = false
        if state == true do(
            p = pickobject prompt:"Pick surface to move to."
            targetMesh = p
            try(
                mouseray = mapScreenToWorldRay mouse.pos
                sectray = intersectRayEx $ mouseray
                Intersectpos = sectray[1].pos
                print "get"
                drawPoints Intersectpos "right"
            )catch(
                print "default"
                Intersectpos = gw.mapCPToWorld (gw.getPointOnCP mouse.pos)
                --drawPoints Intersectpos "left"
            )
        )
    )
    -- end right button event

    -- export button event
    on btn_Export pressed do(

    )
    -- end export button event
    -- end event listeners
)

createdialog DynamicProjection width:500 height:75