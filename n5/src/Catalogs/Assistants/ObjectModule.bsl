#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	deletionChanged = not IsNew () and ( DeletionMark <> DF.Pick ( Ref, "DeletionMark" ) );
	if ( deletionChanged ) then
		Catalogs.Assistants.Unsync ( Ref );
	endif;
	
EndProcedure

#endif
