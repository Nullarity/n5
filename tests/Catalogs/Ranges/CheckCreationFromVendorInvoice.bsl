// Test range creation from Vendor Invoice and Item Balances.
// Will check two cases:
// - Create a new range through List and "+" button there
// - Create a new range from "+" button

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8AC8A7" );
env = getEnv ( id );
createEnv ( env );

// Creation from Vendor Invoice
Commando("e1cib/command/Document.VendorInvoice.Create");
table = Get("#ItemsTable");
Set("#Vendor", env.Vendor);
Set("#Warehouse", env.Warehouse);
Click("#ItemsTableAdd");
Set("#ItemsItem", env.Item);
Set("#ItemsQuantity", env.Quantity);
Set("#ItemsPrice", env.Price);
table.EndEditRow ();

// Click ... and + buttons
Choose("#ItemsRange");
With();
Click("#FormCreate");
With();
if ( Date(1, 1, 1) = Fetch("#Received") ) then
	Stop( "Date of receiving should be filled" );
endif;
Close();
With();
Close();

// Click + button
With();
field = Activate("#ItemsRange");
field.OpenDropList();
field.Create();
With();
if ( Date(1, 1, 1) = Fetch("#Received") ) then
	Stop( "Date of receiving should be filled" );
endif;

Disconnect();

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Warehouse", "Main" );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Price", 1 );
	p.Insert ( "Quantity", 300 );
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
	p.Description = Env.Item;
	p.Form = true;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
