#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( Provider = Enums.AIProviders.Anthropic ) then
		CheckedAttributes.Add ( "Tokens" );
	endif;
	
EndProcedure

#endif