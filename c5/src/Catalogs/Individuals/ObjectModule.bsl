#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	if ( not checkEmail () ) then
		Cancel = true;
	endif; 
	if ( not PhoneTemplates.Check ( ThisObject, "MobilePhone, HomePhone" ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkEmail ()
	
	if ( Email = "" ) then
		return true;
	endif; 
	result = Mailboxes.TestAddress ( Email );
	if ( not result ) then
		Output.InvalidEmail ( , "Email" );
	endif; 
	return result;
	
EndFunction 

#endif