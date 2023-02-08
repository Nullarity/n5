#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	creating = ( FormType = "ObjectForm" ) and not Parameters.Property ( "Key" );
	if ( creating ) then
		StandardProcessing = false;
		SelectedForm = Metadata.Catalogs.Currencies.Forms.Classifier;
	endif; 
	
EndProcedure


#endif