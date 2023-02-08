#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.CreditLimit.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

#endif
