// *****************************************
// *********** Form events

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkEmail () ) then
		Cancel = true;
	endif; 
	if ( not Mailboxes.CheckAddresses ( Record, "Presentation", "Record" ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkEmail ()
	
	result = Mailboxes.TestAddress ( Record.Email );
	if ( not result ) then
		Output.InvalidEmail ( , "Email", , "Record" );
	endif; 
	return result;
	
EndFunction 
