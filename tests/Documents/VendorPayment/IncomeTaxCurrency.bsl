// Create Vendor
// Create three Invoices
// Create Payment
// Set Income Tax
// Change currency
// Post & check

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0UM" );
env = getEnv ( id );
createEnv ( env );

// Create Payment
Commando("e1cib/command/Document.VendorPayment.Create");
With("Vendor Payment (create)");
Put("#Vendor", env.Vendor);
Put("#Amount", 524.54);

Set ("#Account", "2432");
Set ("#VendorAccount", "5212");
Set ("#AdvanceAccount", "2242");
Set ("#IncomeTaxAccount", "5343");
Set ("#Currency", "CAD");
Next();
Set ("#Rate", 15.1779);

Put("#IncomeTax", "CC");
Set("#IncomeTaxRate", 5);
Set("#Payments / #PaymentsAmount[1]", 33.33);
Set("#Payments / #PaymentsAmount[2]", 33.33);
Set("#Payments / #PaymentsAmount[3]", 7894.83);

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
