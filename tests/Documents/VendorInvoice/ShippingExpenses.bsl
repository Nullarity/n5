// Test shipping cost distribution

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A14V" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region CheckRecords
Call ( "Documents.VendorInvoice.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
Click ( "#FormPostAndClose" );
With ();
Click("#FormReportRecordsShow");
With();
CheckTemplate("#TabDoc");
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region vendorInvoice
	p = Call ( "Documents.VendorInvoice.Buy.Params" );
	p.Date = this.Date - 86400*2;
	p.Vendor = this.Vendor;
	items = new Array ();
	row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	row.Item = this.Item1;
	row.Quantity = 10;
	row.Price = 7;
	items.Add ( row );
	row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	row.Item = this.Item2;
	row.Quantity = 30;
	row.Price = 15;
	items.Add ( row );
	p.Items = items;
	p.ID = id;
	p.Date = this.Date - 86400*2;
	Call ( "Documents.VendorInvoice.Buy", p );
	With ();
	Click ( "#Shipping" );
	Set ( "#ShippingPercent", 3 );
	Set ( "#ShippingAccount", "5384" );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
