#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Base;
var Env;
var Realtime;
	
Procedure Filling ( FillingData, StandardProcessing )
	
	Base = FillingData;
	if ( TypeOf ( Base ) = Type ( "DocumentObject.Shipment" ) ) then
		fillByShipment ();
	endif;
	
EndProcedure

Procedure fillByShipment ()
	
	headerByShipment ();
	tablesByShipment ();
	
EndProcedure 

Procedure headerByShipment ()
	
	FillPropertyValues ( ThisObject, Base );
	Number = "";
	Memo = "";
	Date = CurrentSessionDate ();
	Shipment = Base.Ref;
	
EndProcedure 

Procedure tablesByShipment ()
	
	for each row in Base.Items do
		if ( row.Quantity = 0 ) then
			continue;
		endif; 
		newRow = Items.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( row.Item, Company, Sender, "Account" );
		newRow.Account = accounts.Account;
		newRow.AccountReceiver = accounts.Account;
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

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Realtime = Realtime;
	Cancel = not Documents.Transfer.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

#endif
