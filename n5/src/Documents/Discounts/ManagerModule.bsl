#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "To" );
	Fields.Add ( "Number" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.Discounts.Synonym
	+ " #" + Data.Number
	+ ", " + Conversion.DateToString ( Data.Date )
	+ " - " + Conversion.DateToString ( Data.To );
	
EndProcedure

#endif