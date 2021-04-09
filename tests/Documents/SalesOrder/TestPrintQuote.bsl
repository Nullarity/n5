Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27B870B8" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.SalesOrder" );
With ( "Sales Orders" );
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );  

Click ( "#FormDataProcessorQuoteQuote" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Item1", "Item1 " + ID );
	p.Insert ( "Item2", "Item2 " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	 p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	 p.Description = Env.Customer;
	 Call ( "Catalogs.Organizations.CreateCustomer", p );

	 // *************************
	 // Create Warehouse
	 // *************************
	
	 p = Call ( "Catalogs.Warehouses.Create.Params" );
	 p.Description = Env.Customer;
	 Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );

	 // *************************
	 // Create Items
	 // *************************
	
	 p = Call ( "Catalogs.Items.Create.Params" );
	 p.Description = Env.Item1;
	 Call ( "Catalogs.Items.Create", p );

	 p.Description = Env.Item2;
	 Call ( "Catalogs.Items.Create", p );

	// *************************
	// Create SalesOrder
	// *************************

	Commando ( "e1cib/data/Document.SalesOrder" );
	With ( "Sales Order (create)" );
	Put ( "#Customer", Env.Customer );
	Put ( "#DeliveryDate", "01/01/2018" );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Department", Env.Department );
	Put ( "#Memo", id );

	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", Env.Item1 );
	Put ( "#ItemsPrice", "100" );
	Put ( "#ItemsQuantity", "5" );

	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", Env.Item2 );
	Put ( "#ItemsPrice", "200" );
	Put ( "#ItemsQuantity", "2" );
	
	Click ( "#PaymentsAdd" );
	Put ( "#PaymentsPaymentOption", "15#" );


	Click ( "#FormWrite" );
	Click ( "#FormClose" );

	RegisterEnvironment ( id );

EndProcedure
