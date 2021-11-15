// Create Customer
// Set Delivery Days = 10 days
// Create Sales Order
// Check if Delivery Date becomes 10 days after current date

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27081418" );
env = getEnv ( id );
createEnv ( env );

// Create Sales Order
Commando("e1cib/data/Document.SalesOrder");
With("Sales Order (cr*");
Put ("#Customer", env.Customer);

// Check if Delivery Date becomes 10 from current date
deliveryDate = BegOfDay ( CurrentDate () + 86400 * env.Delivery );
Check("#DeliveryDate", deliveryDate);

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Delivery", 10 );
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
	p.Delivery = Env.Delivery;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
