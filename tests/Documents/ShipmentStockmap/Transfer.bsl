// Create Invoice based on Receipt Stockman

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0JZ" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newShipmentStockman
Commando("e1cib/command/Document.ShipmentStockman.Create");
Set ("#Stock", this.Destination);
items = Get ( "#Items" );
Click("#FormAdd");
Pause(1);
With ();
Put ( "#ListSearchString", this.Item );
Click("#FormChoose");
With();
items.EndEditRow ();
Set("#ItemsItem", this.Item, items);
Set("#ItemsQuantityPkg", 5, items);
Click("#FormPost");
#endregion

#region newTransfer
Click("#FormDocumentTransferCreateBasedOn");
With();
Check("#ItemsTotalQuantity", 25);
Click("#JustSave");
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
	this.Insert ( "Destination", "Warehouse " + id );
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

	#region newWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Destination;
	Call ( "Catalogs.Warehouses.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
