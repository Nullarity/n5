#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Inventory.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Procedure Post ( Ref ) export

	RunStockman.MakeBarcodes ( Ref );

EndProcedure

#endif