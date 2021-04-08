#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	checkWarehouse ( CheckedAttributes );
	if ( not PaymentsTable.Check ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	if ( not DeliveryRows.Check ( ThisObject, "Items" )
		or not DeliveryRows.Check ( ThisObject, "Services" ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.PurchaseOrder.Post ( Env );
	
EndProcedure

#endif