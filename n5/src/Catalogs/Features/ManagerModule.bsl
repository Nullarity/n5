#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )

	filterByItem ( Parameters );

EndProcedure

Procedure filterByItem ( Parameters )
	
	item = undefined;
	if ( Parameters.Property ( "Item", item ) ) then
		features = DF.Pick ( item, "Features" );
		Parameters.Filter.Insert ( "Parent", features );
		if ( features.IsEmpty () ) then
			Parameters.Filter.Insert ( "IsFolder", false );
		endif;
	endif;
	
EndProcedure

#endif