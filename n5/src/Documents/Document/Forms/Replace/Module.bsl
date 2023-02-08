
// *****************************************
// *********** Group Form

&AtClient
Procedure Download ( Command )
	
	Close ( DialogReturnCode.Yes );
	
EndProcedure

&AtClient
Procedure Leave ( Command )
	
	Close ( DialogReturnCode.No );
	
EndProcedure
