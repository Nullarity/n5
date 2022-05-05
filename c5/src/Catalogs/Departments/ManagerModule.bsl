#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( Parameters.Property ( "Filter" ) ) then
		augmentFilter ( Parameters.Filter );
	endif;
	
EndProcedure

Procedure augmentFilter ( Filter )
	
	var owner, company;
	augment =
	Filter.Property ( "Owner", owner )
	and ( not ValueIsFilled ( owner )
		or TypeOf ( owner ) <> Type ( "CatalogRef.Companies" ) )
	and Filter.Property ( "Company", company )
	and ValueIsFilled ( company );
	if ( augment ) then
		Filter.Owner = company;
	endif;

EndProcedure

#endif
