#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not PhoneTemplates.Check ( ThisObject, "MobilePhone, BusinessPhone, AdditionalPhone, Fax, HomePhone" ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

#endif