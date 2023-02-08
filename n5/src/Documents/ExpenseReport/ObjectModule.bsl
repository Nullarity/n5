#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Reposted;
var Realtime;	

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( not AssetsForm.CheckDepreciation ( ThisObject, "FixedAssets" ) ) then
		Cancel = true;
		return;
	endif; 
	if ( not AssetsForm.CheckDepreciation ( ThisObject, "IntangibleAssets" ) ) then
		Cancel = true;
		return;
	endif; 
	if ( not checkProducerPrices () ) then
		Cancel = true;
		return;
	endif;
	checkWarehouse ( CheckedAttributes );
	checkVAT ( CheckedAttributes );

EndProcedure

Function checkProducerPrices () 

	s = "
	|// Items
	|select Items.Item as Item, Items.ProducerPrice as Price, Items.LineNumber - 1 as Line
	|into Items
	|from &Items as Items
	|;
	|select Items.Item as Item, Items.Line as Line
	|from Items as Items
	|where Items.Item.Social
	|and Items.Price = 0
	|";
	q = new Query ( s );
	q.SetParameter ( "Items", Items.Unload ( , "Item, ProducerPrice, LineNumber" ) );
	table = q.Execute ().Unload ();
	error = false;
	p = new Structure ( "Item" );
	for each row in table do
		error = true;
		p.Item = row.Item;
		Output.ProducerPriceEmpty ( p, "Items[" + row.Line + "].ProducerPrice" );
	enddo;
	return not error;

EndFunction

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure

Procedure checkVAT ( CheckedAttributes )
	
	if ( VATUse > 0 ) then
		CheckedAttributes.Add ( "Items.VATAccount" );
		CheckedAttributes.Add ( "Services.VATAccount" );
		CheckedAttributes.Add ( "FixedAssets.VATAccount" );
		CheckedAttributes.Add ( "IntangibleAssets.VATAccount" );
		CheckedAttributes.Add ( "Accounts.VATAccount" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not IsNew () ) then
		Catalogs.Lots.Sync ( Ref, DeletionMark );
		deletePayments ();
	endif; 
	setProperties ();
	
EndProcedure

Procedure deletePayments ()
	
	if ( not DeletionMark ) then
		return;
	endif;
	for each row in findPayments () do
		obj = row.Ref.GetObject ();
		obj.SetDeletionMark ( true );
	enddo;
	
EndProcedure 

Function findPayments ()
	
	s = "
	|select Documents.Ref as Ref
	|from Document.VendorPayment as Documents
	|where Documents.ExpenseReport = &Ref
	|and not Documents.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure setProperties ()
	
	Reposted = Posted;
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Reposted = Reposted;
	Env.Realtime = Realtime;
	Cancel = not Documents.ExpenseReport.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	
EndProcedure

#endif