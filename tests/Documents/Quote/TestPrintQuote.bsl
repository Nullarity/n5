Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2729E2FB" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.Quote" );
With ( "Quotes" );
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
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
	Call ( "Catalogs.Items.Create", p );

	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p );

	// *************************
	// Create Quote
	// *************************

	Commando ( "e1cib/data/Document.Quote" );
	With ( "Quote (create)" );
	Put ( "#Customer", Env.Customer );
	Put ( "#DeliveryDate", "01/01/2018" );
	Put ( "#DueDate", "02/01/2018" );
	Put ( "#Warehouse", Env.Warehouse );
	PUt ( "#Memo", id );

	Click ( "#ItemsAdd" );
	Put ( "#ItemsItem", Env.Item1 );
	Put ( "#ItemsPrice", "100" );
	Put ( "#ItemsQuantity", "5" );

	Click ( "#ItemsAdd" );
	Put ( "#ItemsItem", Env.Item2 );
	Put ( "#ItemsPrice", "200" );
	Put ( "#ItemsQuantity", "2" );


	Click ( "#FormWrite" );
	Click ( "#FormClose" );

	RegisterEnvironment ( id );

EndProcedure
