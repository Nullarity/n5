
Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	creating = ( FormType = "ObjectForm" ) and not Parameters.Property ( "Key" );
	if ( creating ) then
		StandardProcessing = false;
		SelectedForm = Metadata.Catalogs.PositionsClassifier.Forms.Choice;
	endif; 
	
EndProcedure

