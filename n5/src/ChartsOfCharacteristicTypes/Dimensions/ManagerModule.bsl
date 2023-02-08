
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	if ( Options.Russian () ) then
		StandardProcessing = false;
		Fields.Add ( "DescriptionRu" );
	endif; 
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	if ( Data.Property ( "DescriptionRu" ) ) then
		StandardProcessing = false;
		Presentation = Data.DescriptionRu;
	endif; 
	
EndProcedure

