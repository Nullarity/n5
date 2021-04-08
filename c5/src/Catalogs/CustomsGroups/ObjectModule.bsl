Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkDoubles () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function checkDoubles ()
	
	doubles = Collections.GetDoubles ( Charges, "Charge" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			OutputCont.DoubleCustomsCharges ( , Output.Row ( "Charges", row.LineNumber, "Charge" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 
