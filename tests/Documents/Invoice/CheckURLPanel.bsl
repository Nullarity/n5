// Create Invoice
// Create & Close Payment
// Check if Invoice shows link to the Payment

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27E40A43" );
env = getEnv ( id );
createEnv ( env );

// Create Invoice
Commando("e1cib/command/Document.Invoice.Create");
With();
Set("#Customer", env.Customer);
Click("#ServicesAdd");
Set("#ServicesItem", env.Service);
Set("#ServicesQuantity", 1);
Set("#ServicesPrice", 150);
Click("#FormPost");

// Create & Close Payment
Click("#FormDocumentPaymentCreateBasedOn");
With();
Click("#FormPostAndClose");

// Check if Invoice shows link to the Payment
With();
CheckState("#Links", "Visible");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Service", "Service " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Service = true;
	p.Description = Env.Service;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
