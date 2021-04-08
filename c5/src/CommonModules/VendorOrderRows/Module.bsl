Procedure SetAllocatedDocumentOrder ( TableRow ) export
	
	if ( TableRow.Provision <> PredefinedValue ( "Enum.Provision.Directly" ) ) then
		TableRow.DocumentOrder = undefined;
		TableRow.DocumentOrderRowKey = undefined;
	endif; 
	
EndProcedure

Procedure ResetProvision ( TableRow ) export
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	if ( TableRow.Provision = PredefinedValue ( "Enum.Provision.Directly" )
		and not ValueIsFilled ( TableRow.DocumentOrder ) ) then
		TableRow.Provision = PredefinedValue ( "Enum.Provision.None" );
	endif; 
	
EndProcedure
