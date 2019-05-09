rollout DynamicProjection "Dynamic Projection"
(
    -- rollout ui
	editText edit_FilePath   "File Name" pos:[20,  15] width:250
	button   btn_Browse      "Browse..." pos:[287, 13]
    spinner  spin_Radius     "Radius"    pos:[43,  45] width:70  type:#integer range:[20,600,20] 
    button   btn_Left        "Left"      pos:[220, 42] width:60
	button   btn_Right       "Right"     pos:[290, 42] width:60
	button   btn_Export      "Export"    pos:[370, 13] width:110 height:50
    -- end rollout ui

    -- read data from csv
    fn readFile path = (
        print "read csv file"
        AssyFile = openfile path
        if (AssyFile != undefined) then
        (
            skiptonextline AssyFile
            while not eof AssyFile do(
                index = readvalue AssyFile
                leftX = readValue AssyFile
                leftY = readValue AssyFile
                rightX = readValue AssyFile
                rightY = readValue AssyFile
                -- print leftX leftY rightX rightY
                format "left X : %, left Y : %\nright X : %, right Y : %\n" leftX leftY rightX rightY
            )
        )
        else( messageBox "Open Failed" title:"Error!" )
    )
    -- end read data from csv
    
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
    on btn_Left pressed do(
        
    )
    -- end left button event

    -- right button event
    on btn_Right pressed do(

    )
    -- end right button event

    -- export button event
    on btn_Export pressed do(

    )
    -- end export button event
    -- end event listeners
)

createdialog DynamicProjection width:500 height:75