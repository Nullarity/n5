#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var DescriptionChanged;
	
Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	DescriptionChanged = Description <> DF.Pick ( Ref, "Description", "" );

EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DescriptionChanged ) then
		EmbeddingGetter.Enroll ( Ref );
	endif;
	
EndProcedure

#endif