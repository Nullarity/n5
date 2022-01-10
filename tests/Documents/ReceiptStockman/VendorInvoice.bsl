// Create Vendor Invoice based on Receipt Stockman

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0KW" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newReceiptStockman
Commando("e1cib/command/Document.ReceiptStockman.Create");
Set ("#Organization", this.Vendor);
items = Get ( "#Items" );
Click("#FormAdd");
Pause (1);
With ();
Put ( "#ListSearchString", this.Item );
Click("#FormChoose");
With();
items.EndEditRow ();
Set("#ItemsItem", this.Item, items);
Set("#ItemsQuantityPkg", 5, items);
Click("#FormPost");
#endregion

#region newVI
Click("#FormDocumentVendorInvoiceCreateBasedOn");
With();
Check("#ItemsTotalQuantity", 25);
Click("#FormPost");
CheckErrors();
Close ();
#endregion

#region checkReceiptAvailability
With();
CheckState("#Links", "Visible");
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region newVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
