#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Number" );
	Fields.Add ( "Start" );
	Fields.Add ( "Subject" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.Event.Synonym + " #" + Data.Number + ", " + Conversion.DateToString ( Data.Start )
		+ ", " + Data.Subject;
	
EndProcedure

#endif
