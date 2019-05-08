rollout DynamicProjection "Dynamic Projection"
(
    --rollout ui
	editText edit_FilePath  "File Name" pos:[20,15]  width:250
	button btn_Browse       "Browse..." pos:[287,13]
    spinner spin_Radius     "Radius"    pos:[43,45]  width:70  type:#integer range:[20,600,20] 
    button  btn_Left        "Left"      pos:[220,42] width:60
	button  btn_Right       "Right"     pos:[290,42] width:60
	button  btn_Export      "Export"    pos:[370,13] width:110 height:50
    --end rollout ui

    --event listeners
    on btn_Browse pressed do
    (
        dlg = dotNetObject "System.Windows.Forms.OpenFileDialog"
        dlg.title = "Please select a CSV file to get point data"
        dlg.Multiselect = false
        dlg.Filter = "CSV files (*.csv)|*.csv|All Files (*.*)|*.*"
        result = dlg.showDialog()
        if(result.Equals result.OK) do(
            edit_FilePath.text = dlg.fileName
        )
    )
    --end event listeners
)

createdialog DynamicProjection width:500 height:75