// Open Production Orders list
// Set Filter by Workshop
// Create a new Document and check Workshop
// Close Document
// Set Filter by Warehouse
// Create a new Document and check Workshop

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27BF45AB" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/list/Document.ProductionOrder");
With();
Set("#WorkshopFilter", Env.Workshop);
Next ();
Click("#FormCreate");
With();
Check("#Workshop", Env.Workshop);
Close ();
With();
Set("#WarehouseFilter", Env.Warehouse);
Next ();
Click("#FormCreate");
With();
Check("#Warehouse", Env.Warehouse);

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Workshop", "Workshop " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
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
	
	RegisterEnvironment ( id );
	
EndProcedure
