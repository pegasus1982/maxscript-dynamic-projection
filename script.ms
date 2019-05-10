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

    --global mat_pink_opacity = StandardMaterial()
    --mat_pink_opacity.name = ("mat_pink_opacity")

    global object_to_align
    global surface_obj
    global original_TM

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
            --print "left point array"
            --print originLeftPointArray
            --print "right point array"
            --print originRightPointArray
        )
        else( messageBox "Open Failed" title:"Error!" )
    )
    -- end read data from csv
    
    -- create points collection
    fn createController type = (
        local clr
        if type == "left" then(clr = color_pink) else(clr = color_cyan)
        object_to_align.material = StandardMaterial diffuse:clr opacity:30 name:("mat_controller_opacity")

        center = box()
        center.length = 3
        center.width = 3
        center.height = 3
        center.name = (type+"_collection_controller_center")
        center.pos = object_to_align.pos
        center.dir = object_to_align.dir
        center.wirecolor = clr

        diameter = Cylinder()
        diameter.radius = 0.75
        diameter.height = object_to_align.radius
        diameter.name = (type+"_collection_controller_diameter")
        diameter.pos = object_to_align.pos
        diameter.pivot = object_to_align.pos
        diameter.dir = object_to_align.dir
        diameter.transform = (rotateYmatrix 90) * diameter.transform
        diameter.wirecolor = clr
        
        rotate_handle = sphere()
        rotate_handle.radius = 1.6
        rotate_handle.name = (type+"_collection_controller_rotate_handle")
        rotate_handle.pos = object_to_align.pos
        rotate_handle.pivot = object_to_align.pos
        rotate_handle.dir = object_to_align.dir
        in coordsys #local rotate_handle.pos.x += object_to_align.radius
        rotate_handle.wirecolor = clr

        object_to_align.parent = center
        diameter.parent = center
        rotate_handle.parent = center
        in coordsys #local center.pos.z += 3

        return center
    )
    fn createCollection = (
        print "create controller"
        if btn_Left.checked == true then (
            print "for left"
            btn_Left.checked = false

            leftCollectionController = createController "left"
            --print a
        )
        else(
            print "for right"
            btn_Right.checked = false

            rightCollectionController = createController "right"
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
            format "Align Object To Face Finished.\n" 
            createCollection()
            return #end
        )
    )
    -- and assign controller to surface
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
            object_to_align = Cylinder()
            object_to_align.radius = 30
            object_to_align.height = 0.5
            object_to_align.name = "left_collection_controller"

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
            object_to_align = Cylinder()
            object_to_align.radius = 30
            object_to_align.height = 0.5
            object_to_align.name = "right_collection_controller"

            surface_obj = pickobject prompt:"Pick surface to move to."
            original_TM = object_to_align.transform
            a = mouseTrack on:surface_obj trackCallback:assign_normal
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