// Give Payment $100
// Create VendorInvoice $150
// Check Advance & Debt

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28E7B044" );
env = getEnv ( id );
createEnv ( env );

// Create VendorInvoice $150
Commando("e1cib/command/Document.VendorInvoice.Create");
With();
Set("#Vendor", env.Vendor);
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
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Service", "Service " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
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
	
	Commando("e1cib/command/Document.VendorPayment.Create");
	With();
	Set("#Vendor", env.Vendor);
	Set("#Amount", 100);
	Click("#FormPostAndClose");
	
	RegisterEnvironment ( id );
	
EndProcedure
