#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.LoadPayments.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#endif