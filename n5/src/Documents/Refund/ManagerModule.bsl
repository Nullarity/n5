#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.IncomingFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.IncomingPresentation ( Metadata.Documents.Refund.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#endif