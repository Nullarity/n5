// Will do re-grading process:
// - Item1 & Item2 are in shortage, Item3 & Item4 are in surplus.
// - Using Assembling & Disassembling will re-grade theese items.

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0R0" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region openInventory
Call("Documents.Inventory.ListByMemo", id);
With();
Click("#FormChange");
#endregion 	

#region newAssebmling
With();
Click ( "#FormDocumentAssemblingCreateBasedOn" );
With ();
Set("#Set", this.Regrading);
Check("#ItemsTotalCost", 1000);
Set("#QuantityPkg", 1000);
Click("#FormPostAndClose");
#endregion         

#region newDisassembling
With ();
Click("#FormDocumentDisassemblingCreateBasedOn");
With ();
Set("#Set", this.Regrading);
Set("#QuantityPkg", 1000);
Click("#FormPost");
Click("#FormReportRecordsShow");
With ();
CheckTemplate( "#TabDoc" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Warehouse", "Warehouse " + id );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );
	this.Insert ( "Item3", "Item3 " + id );
	this.Insert ( "Item4", "Item4 " + id );
	this.Insert ( "Regrading", "Regrading " + id );

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

	#region newItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Regrading;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item1;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item2;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item3;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item4;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item1;
	row.Quantity = 100;
	row.Price = 5;
	items.Add ( row );
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item2;
	row.Quantity = 100;
	row.Price = 15;
	items.Add ( row );
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item3;
	row.Quantity = 100;
	row.Price = 5;
	items.Add ( row );
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item4;
	row.Quantity = 100;
	row.Price = 15;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Warehouse = this.Warehouse;
	p.Account = "6111";
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region Inventory
	Commando("e1cib/command/Document.Inventory.Create");
	Put("#Date", this.Date - 86400);
	Put("#Warehouse", this.Warehouse);
	Put("#Memo", id);
	Click("#ItemsFill");
	Put("#ItemsTable / #ItemsQuantity [1]", 50);
	Put("#ItemsTable / #ItemsQuantity [2]", 50);
	Put("#ItemsTable / #ItemsQuantity [3]", 150);
	Put("#ItemsTable / #ItemsQuantity [4]", 150);
	Click ( "#FormPost" );
	#endregion

	CloseAll ();
	
	RegisterEnvironment ( id );

EndProcedure
