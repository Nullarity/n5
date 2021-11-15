// Take Payment $100
// Create Invoice $150
// Check Advance & Debt

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28E793B6" );
env = getEnv ( id );
createEnv ( env );

// Create Invoice $150
Commando("e1cib/command/Document.Invoice.Create");
With();
Set("#Customer", env.Customer);
Click("#ServicesAdd");
Set("#ServicesItem", env.Service);
Set("#ServicesQuantity", 1);
Set("#ServicesPrice", 150);
Click("#FormPost");

// Check Advance & Debt
Click("#FormReportRecordsShow");
With();
CheckTemplate("#TabDoc");

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
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Service = true;
	p.Description = Env.Service;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Payment
	// *************************
	
	Commando("e1cib/command/Document.Payment.Create");
	With();
	Set("#Customer", env.Customer);
	Set("#Amount", 100);
	Click("#FormPostAndClose");
	
	RegisterEnvironment ( id );
	
EndProcedure
