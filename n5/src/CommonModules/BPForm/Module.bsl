Procedure ShowChart ( Reference, Process, Owner = undefined ) export
	
	OpenForm ( "CommonForm.Chart", new Structure ( "Reference, Process", Reference, Process ), Owner );
	
EndProcedure