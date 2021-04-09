// Create Vendor
// Create three Invoices
// Create Payment
// Set Income Tax
// Post & check

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A61A67C" );
env = getEnv ( id );
createEnv ( env );

// Create Payment
Commando("e1cib/command/Document.VendorPayment.Create");
With("Vendor Payment (create)");
Put("#Vendor", env.Vendor);

Click("#Payments / #PaymentsPay[1]");
Click("#Payments / #PaymentsPay[2]");
Click("#Payments / #PaymentsPay[3]");
Put("#IncomeTax", "CC");
Set("#IncomeTaxRate", 5);
Next();
Check("#IncomeTaxAmount", 15);
Check("#Total", 285);

// Post & Check
Click("#FormPost");

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
	p.Insert ( "Price", 100 );
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
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Invoices
	// *************************
	
	For i = 0 To 2 Do
		Commando("e1cib/command/Document.VendorInvoice.Create");
		With("Vendor Invoice (create)");
		Set("#Vendor", env.Vendor);
		table = Get("#Services");
		Click("#ServicesAdd");
		Set("#ServicesItem", env.Service);
		Set("#ServicesQuantity", 1);
		Set("#ServicesPrice", env.Price);
		Put("#ServicesExpense","Others");
		Click("#FormPostAndClose");
	EndDo;
	
	RegisterEnvironment ( id );
	
EndProcedure
