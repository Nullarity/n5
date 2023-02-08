#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkEmail () ) then
		Cancel = true;
	endif; 
	if ( not PhoneTemplates.Check ( ThisObject, "MobilePhone, BusinessPhone, AdditionalPhone, Fax, HomePhone" ) ) then
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

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		recheckEmail ();
	endif; 
	
EndProcedure

Procedure recheckEmail ()
	
	if ( Email = "" ) then
		return;
	endif; 
	result = Mailboxes.TestAddress ( Email );
	if ( not result ) then
		Email = "";
	endif; 
	
EndProcedure

#endif