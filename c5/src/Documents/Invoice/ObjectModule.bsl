#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Base;
var Realtime;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	checkWarehouse ( CheckedAttributes );
	checkVAT ( CheckedAttributes );
	checkAdvanceAccount ( CheckedAttributes );
	
EndProcedure

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure 

Procedure checkVAT ( CheckedAttributes )
	
	if ( VATUse > 0 ) then
		CheckedAttributes.Add ( "Items.VATAccount" );
		CheckedAttributes.Add ( "Services.VATAccount" );
		CheckedAttributes.Add ( "Discounts.VATAccount" );
	endif; 
	
EndProcedure 

Procedure checkAdvanceAccount ( CheckedAttributes )
	
	if ( CloseAdvances ) then
		CheckedAttributes.Add ( "AdvanceAccount" );
		CheckedAttributes.Add ( "ReceivablesVATAccount" );
		CheckedAttributes.Add ( "VATAdvance" );
	endif; 
	
EndProcedure 

Procedure Filling ( FillingData, StandardProcessing )
	
	Base = FillingData;
	baseType = TypeOf ( Base );
	if ( baseType = Type ( "DocumentObject.Shipment" ) ) then
		fillByShipment ();
	endif;
	
EndProcedure

Procedure fillByShipment ()
	
	headerByShipment ();
	tablesByShipment ();
	DiscountsTable.Load ( ThisObject );
	InvoiceForm.CalcTotals ( ThisObject );
	InvoiceForm.SetPayment ( ThisObject );

EndProcedure 

Procedure headerByShipment ()
	
	FillPropertyValues ( ThisObject, Base );
	Number = "";
	Memo = "";
	Date = CurrentSessionDate ();
	Shipment = Base.Ref;
	data = AccountsMap.Organization ( Customer, Company, "CustomerAccount, AdvanceTaken" );
	CustomerAccount = data.CustomerAccount;
	CloseAdvances = DF.Pick ( Contract, "CustomerAdvances" );
	
EndProcedure 

Procedure tablesByShipment ()
	
	for each row in Base.Items do
		if ( row.Quantity = 0 ) then
			continue;
		endif; 
		newRow = Items.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( row.Item, Company, Warehouse, "Account, SalesCost, Income, VAT" );
		newRow.Account = accounts.Account;
		newRow.SalesCost = accounts.SalesCost;
		newRow.Income = accounts.Income;
		newRow.VATAccount = accounts.VAT;
	enddo; 
	for each row in Base.Services do
		newRow = Services.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( row.Item, Company, Warehouse, "Income, VAT" );
		newRow.Income = accounts.Income;
		newRow.VATAccount = accounts.VAT;
	enddo; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		InvoiceRecords.Delete ( ThisObject );
	endif;
	setProperties ();
	resetAction ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure resetAction ()
	
	if ( not Action.IsEmpty () ) then
		Action = undefined;
	endif; 
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	env.Interactive = Posting.Interactive ( ThisObject );
	Cancel = not Documents.Invoice.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

#endif