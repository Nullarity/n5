
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not ( checkDates ()
		and checkDoubles () ) ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkDates  ()
	
	if ( Periods.Ok ( Produced, ExpirationDate ) ) then
		return true;
	endif;
	Output.PeriodError ( , "ExpirationDate" );
	return false;
	
EndFunction

Function checkDoubles ()
	
	if ( IsInRole ( Metadata.Roles.DoublesAllowed ) ) then
		return true;
	endif; 
	SetPrivilegedMode ( true );
	original = DF.GetOriginal ( Ref, "Lot", Lot, Owner );
	if ( original = undefined ) then
		return true;
	endif; 
	Output.ObjectNotOriginal ( new Structure ( "Value", Lot ), "Lot" );
	return false;
	
EndFunction 
