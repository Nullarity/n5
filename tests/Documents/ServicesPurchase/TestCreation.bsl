// - Create Vendor Invoice
// - Create Services Purchase
// - Check Template

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AA08C" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Invoice
// *************************
	
Commando("e1cib/command/Document.VendorInvoice.Create");
With();
Put("#Vendor", env.Vendor);
Click("#ServicesAdd");
Put("#ServicesItem", env.Service);
Set("#ServicesQuantity", "5.00");
Set("#ServicesPrice", "100.00");
Put("#ServicesExpense", env.Expense);
Click("#FormPost");

// *************************
// Create Items Purchase
// *************************

Click("#FormDocumentServicesPurchaseCreateBasedOn");
With();
Put("#Responsible", env.Responsible);
Put("#Surcharges", env.Surcharges);
Put("#Discount", env.Discount);
Put("#IncomeTax", env.IncomeTax);
Put("#IncomeTaxRate", env.IncomeTaxRate);
Put("#Advance", env.Advance);
Put ( "#Status", "Printed" );
Set ( "#Number", ID );
With();
Click ( "Yes" );

With();
Click("#FormPost");

// *************************
// Check Template
// *************************

Click("#FormDocumentServicesPurchaseServicesPurchase");
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
	p.Insert ( "Responsible", "Responsible " + ID );
	p.Insert ( "IncomeTax", "CC" );
	p.Insert ( "IncomeTaxRate", "10.00" );
	p.Insert ( "Advance", "50.00" );
	p.Insert ( "Surcharges", "40.00" );
	p.Insert ( "Discount", "50.00" );
	p.Insert ( "Expense", "Expense " + ID );
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
	// Create Responsible
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Expense
	// *************************
	
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	RegisterEnvironment ( id );
	
EndProcedure