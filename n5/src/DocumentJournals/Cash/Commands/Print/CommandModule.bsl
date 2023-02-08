
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	print ( List, Type ( "DocumentRef.CashReceipt" ) );
	print ( List, Type ( "DocumentRef.CashVoucher" ) );
	
EndProcedure

&AtClient
Procedure print ( List, Type )
	
	scope = new Array ();
	for each ref in List do
		if ( TypeOf ( ref ) = Type ) then
			scope.Add ( ref );
		endif; 
	enddo; 
	if ( scope.Count () > 0 ) then
		PettyCash.Output ( scope );
	endif; 
	
EndProcedure 