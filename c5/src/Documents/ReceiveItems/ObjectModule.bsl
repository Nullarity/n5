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
		OutputCont.ProducerPriceEmpty ( p, "Items[" + row.Line + "].ProducerPrice" );
	enddo;
	return not error;

EndFunction

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not IsNew () ) then
		Catalogs.Lots.Sync ( Ref, DeletionMark );
	endif; 
	setProperties ();
	
EndProcedure

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
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Reposted = Reposted;
	env.Realtime = Realtime;
	Cancel = not Documents.ReceiveItems.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	
EndProcedure

#endif