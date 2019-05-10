MacroScript AlignToFace category:"Bobo_s Tools"
(
	----------------------------------------------------------------------------------------
	--   Script Name:	AlignObjectToFace
	--	 Version:		v0.12
	--	 Started:       04/29/2001
	--	 Last Modified: 04/30/2001
	--   Description:	Mouse Tool similar to Autogrid, but for existing objects.
	--	 Documentation: Visit http://www.gfxcentral.com/bobo/mxs4/alignobject2face
	--	 Code by:		Borislav Petrov [Boboland]		bobo@email.archlab.tuwien.ac.at
	--					Martin Breidt 					martin@breidt.net
	--
	--   Ideas by: 		Martin Coven, Adrian Tysoe, Martin Breidt, Borislav Petrov
	----------------------------------------------------------------------------------------
	--   NOTE! This tool CANNOT be used from a Quad Menu!!! 
	--   Please use as Keyboard Shortcut or Toolbar icon only!
	----------------------------------------------------------------------------------------


	on isVisible return (selection.count == 1)
	on isEnabled return (selection.count == 1)

	on Execute do 
	(

		fn filter_geometry obj = superclassof obj == GeometryClass and classof obj != TargetObject

		global  AO2F_object_to_align = $
		format "Align Object % - Please Pick Surface To Align To...\n" AO2F_object_to_align.name
		global AO2F_surface_obj = pickobject filter:filter_geometry
		format "Aligning Object % to %\n" AO2F_object_to_align.name AO2F_surface_obj.name
		global AO2F_Original_TM = AO2F_object_to_align.transform


		fn get_normal_function msg ir obj faceNum shift ctrl alt = (
			format "msg : %, ir : %\n" msg ir
			if msg == #freeMove then (
				if ir != undefined then (
					AO2F_object_to_align.pos = ir.pos 
					AO2F_object_to_align.dir = ir.dir

					-- Addition by Martin Breidt
					if ctrl then in coordsys local (rotate AO2F_object_to_align (eulerangles 90 0 0))
					if alt then in coordsys local (rotate AO2F_object_to_align (eulerangles 0 90 0))
					if shift then AO2F_object_to_align.dir *= -1
					-- End Addition 
					
					return #continue
				)
				else(
					return #continue
				)
			)
			if msg == #mouseAbort then (
				AO2F_object_to_align.transform = AO2F_Original_TM 
				format "Align Object To Face Aborted!\n" 
				return #end
			)
			if msg != #mousePoint then (
				return #continue
			)
			else (
				format "Align Object To Face Finished.\n" 
				return #end
			)
		)--end fn

		a = mouseTrack on:AO2F_surface_obj trackCallBack:get_normal_function
	)--end on
)--end script

