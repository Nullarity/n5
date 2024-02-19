#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	Fields.Add ( "Assistant" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = ""
	+ Data.Assistant
	+ " #"
	+ Data.Number
	+ " "
	+ Format ( Data.Date, "DLF=D" );
	
EndProcedure

#endif