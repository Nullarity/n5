#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( not PaymentsTable.CheckQuote ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	if ( not DeliveryRows.Check ( ThisObject, "Items" )
		or not DeliveryRows.Check ( ThisObject, "Services" ) ) then
		Cancel = true;
		return;
	endif; 
	if ( not Periods.Ok ( Date, DueDate ) ) then
		Output.QuoteDateError ( , "DueDate" );
		Cancel = true;
		return;
	endif; 
	checkWarehouse ( CheckedAttributes );
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not checkSales ( WriteMode ) ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkSales ( WriteMode )
	
	dont = ( WriteMode = DocumentWriteMode.UndoPosting )
	or ( WriteMode = DocumentWriteMode.Write and not Posted );
	return dont or Constraints.CheckSales ( ThisObject );

EndFunction

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure 

#endif