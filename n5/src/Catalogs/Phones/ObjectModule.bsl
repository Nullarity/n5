#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		detach ();
	endif; 
	
EndProcedure

Procedure detach ()
	
	if ( Ref = Constants.Phone.Get () ) then
		Constants.Phone.Set ( undefined );
	endif; 
	
EndProcedure 

#endif