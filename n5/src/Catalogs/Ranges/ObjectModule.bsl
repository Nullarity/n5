
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkAttributes ( CheckedAttributes );
	if ( not checkRange () ) then
		Cancel = true;
	endif;
	checkAccount ( CheckedAttributes );
	
EndProcedure

Procedure checkAttributes ( CheckedAttributes )
	
	if ( Online ) then
		CheckedAttributes.Add ( "Description" );
	else
		CheckedAttributes.Add ( "Start" );
		CheckedAttributes.Add ( "Finish" );
		CheckedAttributes.Add ( "Prefix" );
	endif;
	
EndProcedure

Function checkRange ()
	
	if ( Start > Finish ) then
		Output.RangeIncorrect ( , "Finish" );
		return false;
	endif;
	return true;
	
EndFunction

Procedure checkAccount ( CheckedAttributes )
	
	if ( not Item.IsEmpty () ) then
		CheckedAttributes.Add ( "Account" );
		CheckedAttributes.Add ( "ExpenseAccount" );
	endif;
	
EndProcedure

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load
		or DeletionMark) then
		return;
	endif;
	setDescription ();
	
EndProcedure

Procedure setDescription ()
	
	if ( not Online ) then
		Description = "" + Type + " " + TrimR ( Prefix ) + " " + Format ( Start, "NG=" ) + " - " + Format ( Finish, "NG=" );
	endif;
	
EndProcedure
