// *****************************************
// *********** Form events

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	adjustTarget ( CurrentObject );
	
EndProcedure

&AtServer
Procedure adjustTarget ( CurrentObject )
	
	if ( not ValueIsFilled ( CurrentObject.Target ) ) then
		CurrentObject.Target = undefined;
	endif; 
	
EndProcedure 
