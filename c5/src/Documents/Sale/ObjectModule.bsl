#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )

	if ( DataExchange.Load ) then
		return
	endif;
	if ( retailSalesPosted () ) then
		Cancel = true;
		return;
	endif;
	if ( DeletionMark ) then
		InvoiceRecords.Delete ( ThisObject );
	endif;

EndProcedure

Function retailSalesPosted ()
	
	found = false;
	sales = new Array ();
	sales.Add ( Documents.RetailSales.Fetch ( Date, Warehouse, Location, Method ) );
	old = not IsNew ();
	if ( old ) then
		data = DF.Values ( Ref, "Date, Warehouse, Location, Method" );
		if ( BegOfDay ( data.Date ) <> BegOfDay ( Date )
			or data.Warehouse <> Warehouse
			or data.Location <> Location
			or data.Method <> Method ) then
			sales.Add ( Documents.RetailSales.Fetch ( data.Date, data.Warehouse, data.Location, data.Method ) );
		endif;
	endif;
	msg = new Structure ( "Document" );
	for each document in sales do
		if ( document <> undefined ) then
			msg.Document = document;
			Output.RetailSalesPosted ( msg, , document );
			found = true;
		endif;
	enddo;
	return found;

EndFunction

Procedure OnWrite ( Cancel )
	
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.Sale.Post ( env );
	
EndProcedure

#endif
