#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	defaultName ();
	
EndProcedure

Procedure defaultName ()
	
	if ( Description = "" ) then
		Description = Output.WorkingDescription ();
	endif; 
	
EndProcedure 

#endif