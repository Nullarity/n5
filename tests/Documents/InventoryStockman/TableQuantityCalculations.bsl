// Create a new document and play with quantity in the items table

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0JO" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

MainWindow.ExecuteCommand("e1cib/command/Document.InventoryStockman.Create");
Pause(1);
Close("Scan"); // Will appear automatically after document creation
With ();

Click ( "#FormAdd" );
items = Get ( "#Items" );
items.EndEditRow ();
Set ( "#ItemsItem", this.Item, items );
Check("#ItemsPackage", "PK", items);
Set ( "#ItemsQuantityPkg", 2, items );
Check("#ItemsQuantity", 10, items);
Set ( "#ItemsQuantity", 15, items );
Check("#ItemsQuantityPkg", 3, items);

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
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
	p.Capacity = 5;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
