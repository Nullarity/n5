// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setCurrentDate ();
	
EndProcedure

&AtServer
Procedure setCurrentDate ()
	
	CurrentDate = CurrentSessionDate ();
	
EndProcedure 

// *****************************************
// *********** Group List

&AtClient
Procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = not hasAccess ( Item.SelectedRows );
	
EndProcedure

&AtServer
Function hasAccess ( val Rows )
	
	for each row in Rows do
		if ( not InformationRegisters.Rights.Allowed ( row.Target ) ) then
			return false;
		endif; 
	enddo; 
	return true;
	
EndFunction 
