// Check cost sequence

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A12W" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region repostReceipt
Call ( "Documents.VendorInvoice.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
Click ( "#FormPostAndClose" );
#endregion

#region restoreCost
Commando ( "e1cib/app/DataProcessor.Cost" );
Click ( "#Restore" );
Pause ( 2 * __.Performance );
CheckErrors ();
Close ();
#endregion

#region checkVendorReturn
Call ( "Documents.VendorReturn.ListByMemo", id );
With ();
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

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

	#region resetCost
	Commando ( "e1cib/app/DataProcessor.Cost" );
	Click ( "#FormReset" );
	Close ();
	#endregion
	
	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item1;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item2;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region receiveItems
	p = Call ( "Documents.VendorInvoice.Buy.Params" );
	p.Date = this.Date - 86400*2;
	p.Vendor = this.Vendor;
	p.Warehouse = "Main";
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
	Call ( "Documents.VendorInvoice.Buy", p );
	#endregion
	
	#region vendorReturn
	With ();
	Click("#FormDocumentVendorReturnCreateBasedOn");
	With();
	Set ( "#Memo", id );
	Click("#FormPostAndClose");
	#endregion
	RegisterEnvironment ( id );

EndProcedure
