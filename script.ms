rollout DynamicProjection "Dynamic Projection"
(
	editText edit_FilePath  "File Name" pos:[20,15]  width:250
	button btn_Browse       "Browse..." pos:[287,13]
    spinner spin_Radius     "Radius"    pos:[43,45]  width:70  type:#integer range:[20,600,20] 
    button  btn_Left        "Left"      pos:[220,42] width:60
	button  btn_Right       "Right"     pos:[290,42] width:60
	button  btn_Export      "Export"    pos:[370,13] width:110 height:50
)

createdialog DynamicProjection width:500 height:75