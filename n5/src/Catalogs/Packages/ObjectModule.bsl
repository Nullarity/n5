
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkOwner ( CheckedAttributes );
	
EndProcedure

Procedure checkOwner ( Fields )
	
	var dont;
	if ( AdditionalProperties.Property ( Enum.AdditionalPropertiesDontCheckOwner (), dont )
		and dont ) then
		Fields.Delete ( Fields.Find ( "Owner" ) );
	endif; 

EndProcedure