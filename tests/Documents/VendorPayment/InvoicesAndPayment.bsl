// Create Vendor
// Create two Invoices
// Create Payment
// Set Payment amount & check distribution by invoices. Payment amount will cover Invoice1 and 50% of Invoice2
// Uncheck Pay's flags and check if Payment amount changes
// Click Pay checkbox for the first invoice
// Set Payment Amount = 0 for the second invoice and check Pay flag
// Make overpayment for the second invoice
// Uncheck Pay's flags for the first invoice and update table
// Check if total payment is correct and checkbox for second invoice is automatically enabled
// Click Save and check rows count: should be 1 row only
// Refill document and post

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286CF2F6" );
env = getEnv ( id );
createEnv ( env );

// Create Payment
Commando("e1cib/command/Document.VendorPayment.Create");
With("Vendor Payment (create)");
Put("#Vendor", env.Vendor);

// Set Payment amount & check distribution by invoices. Payment amount will cover Invoice1 and 50% of Invoice2
amount = env.Price * 1.5;
Set("#Amount", amount );
Next ();
Check("#Payments / #PaymentsPay[1]", "Yes");
Check("#Payments / #PaymentsPay[2]", "Yes");
Check("#Payments / #PaymentsAmount[1]", 100.00);
Check("#Payments / #PaymentsAmount[2]", 50.00);

// Uncheck Pay's flags and check if Payment amount changes
Click("#Payments / #PaymentsPay[1]");
Check("#Amount", 50.00 );

// Click Pay checkbox for the first invoice
Click("#Payments / #PaymentsPay[1]");
Check("#Payments / #PaymentsAmount[1]", 100.00);

// Click Pay checkbox for the first invoice
// Set Payment Amount = 0 for the second invoice and check Pay flag
Set("#Payments / #PaymentsAmount[2]", 0);
Check("#Payments / #PaymentsPay[2]", "No");

// Make overpayment for the second invoice
Set("#Payments / #PaymentsAmount[2]", env.Price + 10 );
Check("#Payments / #PaymentsOverpayment[2]", 10.00);

// Uncheck Pay's flags for the first invoice and update table
Click("#Payments / #PaymentsPay[1]");
Click("#Update");
Click("Yes");

// Check if total payment is correct and checkbox for second invoice is automatically enabled
Check("#Payments / #PaymentsPay[1]", "No");
Check("#Amount", env.Price + 10 );

// Click save and check rows count: it should be 1 row only
Click("#FormWrite");
invoices = Call("Table.Count", Get("#Payments"));
if (invoices <> 1) then
	Stop("Only 1 Invoice should left in the documents list");
endif;

// Refill document and post
Set("#Amount", env.Price );
Click("#Refill");
Click("Yes");
Click("#FormPost");

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
	
	For i = 0 To 1 Do
		Commando("e1cib/command/Document.VendorInvoice.Create");
		With("Vendor Invoice (create)");
		Set("#Vendor", env.Vendor);
		table = Get("#Services");
		Click("#ServicesAdd");
		Set("#ServicesItem", env.Service);
		Set("#ServicesQuantity", 1);
		Set("#ServicesPrice", env.Price);
		Put("#ServicesExpense","Others");
		Put ( "#TaxCode", "Non-Taxable Sales" );
		Click("#FormPostAndClose");
	EndDo;
	
	RegisterEnvironment ( id );
	
EndProcedure
