#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Reposted;
var Realtime;	

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( not Periods.Ok ( BegOfDay ( Date ), PaymentDate ) ) then
		Output.PaymentDateError ( , "PaymentDate" );
		Cancel = true;
		return;
	endif; 
	checkVAT ( CheckedAttributes );
	if ( not checkServices () ) then
		Cancel = true;
		return;
	endif; 
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
	checkAdvanceAccount ( CheckedAttributes );
	checkShipping ( CheckedAttributes );

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

Function checkServices ()
	
	error = false;
	msg = new Structure ( "Field", Metadata ().TabularSections.Services.Attributes.Account.Presentation () );
	for each row in Services do
		if ( row.IntoFixedAssets
			or row.IntoIntangibleAssets
			or row.IntoItems ) then
			continue;
		endif; 
		if ( row.Account.IsEmpty () ) then
			Output.FieldIsEmpty ( msg, Output.Row ( "Services", row.LineNumber, "Account" ), Ref );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction 

Function checkProducerPrices () 

	table = getItems ();
	if ( table.Count () = 0 ) then
		return true;
	endif;
	p = new Structure ( "Item" );
	for each row in table do
		p.Item = row.Item;
		Output.ProducerPriceEmpty ( p, "Items[" + row.Line + "].ProducerPrice" );
	enddo;
	return false;

EndFunction

Function getItems () 

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
	return q.Execute ().Unload ();

EndFunction

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure 

Procedure checkAdvanceAccount ( CheckedAttributes )
	
	if ( CloseAdvances ) then
		CheckedAttributes.Add ( "AdvanceAccount" );
	endif; 
	
EndProcedure 

Procedure checkShipping ( CheckedAttributes )
	
	if ( Shipping ) then
		CheckedAttributes.Add ( "ShippingPercent" );
		CheckedAttributes.Add ( "ShippingAmount" );
		CheckedAttributes.Add ( "ShippingAccount" );
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

Procedure Posting ( Cancel,  PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Reposted = Reposted;
	Env.Realtime = Realtime;
	Cancel = not Documents.VendorInvoice.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	if ( Dependencies.Exist ( Ref ) ) then
		Cancel = true;
		return;
	endif; 
	Dependencies.Unbind ( Ref );
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	
EndProcedure

#endif