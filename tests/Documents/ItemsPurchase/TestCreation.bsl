// - Create Vendor Invoice
// - Create Items Purchase
// - Check Template

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AA0A2" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Invoice
// *************************
	
Commando("e1cib/command/Document.VendorInvoice.Create");
With();
Put("#Vendor", env.Vendor);
Put("#Warehouse", env.Warehouse);
Click("#ItemsTableAdd");
Set("#ItemsItem", env.Item);
Set("#ItemsQuantity", 5);
Set("#ItemsPrice", 100);
Click("#FormPost");

// *************************
// Create Items Purchase
// *************************

Click("#FormDocumentItemsPurchaseCreateBasedOn");
With();
Put("#Responsible", env.Responsible);
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

Click("#FormDocumentItemsPurchaseItemsPurchase");
With();
CheckTemplate("#TabDoc");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Responsible", "Responsible " + ID );
	p.Insert ( "IncomeTax", "CC" );
	p.Insert ( "IncomeTaxRate", "10.00" );
	p.Insert ( "Advance", "50.00" );
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
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Service = false;
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Responsible
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure