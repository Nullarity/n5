// Create 1 Item & 1 Service
// Create Production Order
// Pick Item
// Pick Service

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A048" );
env = getEnv ( id );
createEnv ( env );

// Create Production Order
Commando("e1cib/command/Document.ProductionOrder.Create");
With();
Set("#Workshop", Env.Workshop);
Set("#Warehouse", Env.Warehouse);
Next ();

// Pick Item
Click("#ItemsSelectItems");
With();
GotoRow("#ItemsList", "Item", env.Item);
if ( Fetch("#AskDetails") = "Yes" ) then
	Click("#AskDetails");
endif;
Get("#ItemsList").Choose ();

// Pick Service
GotoRow("#ItemsList", "Item", env.Service);
Get("#ItemsList").Choose ();
Click("#FormOK");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Workshop", "Workshop " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	p.Production = true;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Workshop
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Workshop;
	p.Production = true;
	p.Department = Env.Department;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Item & Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	p.Description = Env.Service;
	p.Service = true;
	p.Product = true;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
