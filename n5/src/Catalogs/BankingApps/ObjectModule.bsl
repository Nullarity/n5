#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( Application = Enums.Banks.MAIB ) then
		CheckedAttributes.Add ( "Globus" );
	endif;

EndProcedure

#endif