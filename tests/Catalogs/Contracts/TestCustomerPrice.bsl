// Create: Item, Service, Customer, Contract
// Set contract prices
// Create Invoice
// Add a new Item and check price
// Add a new Service and check price

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27387894" );
env = getEnv ( id );
createEnv ( env );

// Create Invoice
Commando ( "e1cib/data/Document.Invoice" );
With ( "Invoice (cr*" );
Put ( "#Customer", env.Customer );

// Check Item Price
Click ( "#ItemsTableAdd" );
Put ( "#ItemsItem", env.Item );
Activate ( "#ItemsPrice" );
Check ( "#ItemsPrice", env.ItemPrice );

// Check Service Price
Click ( "#ServicesAdd" );
Put ( "#ServicesItem", env.Service );
Activate ( "#ServicesPrice" );
Check ( "#ServicesPrice", env.ServicePrice );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "ItemPrice", 150 );
	p.Insert ( "ServicePrice", 250 );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item & Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Customer
	// *************************

	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	item = Call ( "Catalogs.Organizations.CreateCustomer.ContractItem" );
	item.Item = Env.Item;
	item.Price = Env.ItemPrice;
	p.Items.Add ( item  );
	item = Call ( "Catalogs.Organizations.CreateCustomer.ContractService" );
	item.Item = Env.Service;
	item.Price = Env.ServicePrice;
	p.Services.Add ( item  );
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	RegisterEnvironment ( id );

EndProcedure
