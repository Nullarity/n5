#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ShipmentStockman.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Procedure Complete ( Ref ) export
	
	if ( DF.Pick ( Ref, "Invoiced", true ) ) then
		return;
	endif;
	obj = Ref.GetObject ();
	obj.Invoiced = true;
	obj.Write ();
	
EndProcedure

#endif