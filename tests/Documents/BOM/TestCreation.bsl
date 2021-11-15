// Create BOM
// Change fields one by one and check calculations

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27C60400" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Catalog.BOM.Create");
With();
Put ("#Item", env.Item);
Click("#Recalculate");
Set("#QuantityPkg", 5);
Next();
Check("#Quantity", 25);
Put("#Package", "PK");
Put("#Quantity", 50);
Next();
Check("#QuantityPkg", 10);
Clear("#Expense");

// Add component
Click("#ItemsTableAdd");
Put("#ItemsItem", env.Item);
table = Get("#ItemsTable");
table.EndEditRow ();
Set("#ItemsQuantityPkg", 5, table);
Set("#ItemsPackage", "PK", table);
Set("#ItemsQuantity", 50, table);
Set("#ItemsPrice", 3, table);
Check("#ItemsCost", 30, table);
Set("#ItemsCost", 60, table);
Check("#ItemsPrice", 6, table);

// Check totals
Check("#Cost", 60);

Click("#FormWrite");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item;
	p.Product = true;
	Call ( "Catalogs.Items.Create", p);
	
	RegisterEnvironment ( id );
	
EndProcedure
