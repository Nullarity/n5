// Inventry with Inventory Stockman

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0QK" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newInventory
Commando ("e1cib/command/Document.Inventory.Create");
Put("#Warehouse", this.Warehouse);
Click("#ItemsFill");
Click("#FormPost");
#endregion

#region justPrint
Click("#FormDataProcessorInventoryInventory");
Close ( "Inventory: Print" );
#endregion

Click ( "#OpenInventory" );
With ( "Inventory *" );

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Warehouse", "Warehouse " + id );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	#endregion

	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item1;
	row.Quantity = 150;
	row.Price = 7;
	items.Add ( row );
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item2;
	row.Quantity = 300;
	row.Price = 15;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Warehouse = this.Warehouse;
	p.Account = "6111";
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region newStockmanInventory
	Commando ( "e1cib/command/Document.InventoryStockman.Create" );
	Close ( "Scan" );
	Put ( "#Warehouse", this.Warehouse );
	Click ( "#ItemsAdd" );
	Close ( "Items" );
	Items = Get ( "#Items" );
	Set ( "#ItemsItem", this.Item1, Items );
	Set ( "#ItemsQuantity", 100, Items );
	Click ( "#ItemsAdd" );
	Close ( "Items" );
	Set ( "#ItemsItem", this.Item2, Items );
	Set ( "#ItemsQuantity", 100, Items );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
