// Check the correct working of the AddFromInvoice button with the InvoicesInTable:
// - Create VendorInvoice #1
// - Create VendorInvoice #2
// - Create VendorReturn
// - Select VendorInvoice #1
// - Select VendorInvoice #2 
// - Post & CheckTemplate

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6ABF0E" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create VendorInvoice #1
// *************************

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Vendor = env.Vendor;
p.Warehouse = env.Warehouse;
p.ID = id;
items = p.Items;
for each row in env.Items do
	newRow = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	FillPropertyValues ( newRow, row );
	items.Add ( newRow );
enddo;
firstNumber = Call ( "Documents.VendorInvoice.Buy", p ).Number;

// *************************
// Create VendorInvoice #2
// *************************

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Vendor = env.Vendor;
p.Warehouse = env.Warehouse;
p.ID = id;
items = p.Items;
for each row in env.Items do
	newRow = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	FillPropertyValues ( newRow, row );
	items.Add ( newRow );
enddo;
secondNumber = Call ( "Documents.VendorInvoice.Buy", p ).Number;

// *************************
// Create Vendor Return
// *************************

Commando("e1cib/command/Document.VendorReturn.Create");
form = With ( "Return to Vendor (cr*" );
Put ( "#Vendor", env.Vendor );
Put ( "#Warehouse", env.Warehouse );
Put ( "#Memo", id );

// *************************
// Select VendorInvoice #1 
// *************************

Click ( "#ItemsChoiceInvoice", form );
With ( "Vendor Invoices" );
list = Activate ( "#List" );
GotoRow ( list, "Number", firstNumber );
Click ( "#FormChoose" );
With ( "Items" );
Click ( "#FormSelect" );

// *************************
// Select VendorInvoice #2 
// *************************

Click ( "#ItemsChoiceInvoice", form );
With ( "Vendor Invoices" );
list = Activate ( "#List" );
GotoRow ( list, "Number", secondNumber );
Click ( "#FormChoose" );
With ( "Items" );
Click ( "#FormSelect" );

// *************************
// Post & CheckTemplate
// *************************

With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Return *" );
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "01/01/2019" );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Contract", "General" );
	p.Insert ( "Items", getItems ( ID ) );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "10.00", "5" ) );
	list.Add ( getItem ( "Item2 " + ID, "15.00", "10" ) );
	list.Add ( getItem ( "Item3 " + ID, "35.00", "20" ) );
	return list;

EndFunction

Function getItem ( Description, Price, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
	p.Insert ( "Quantity", Quantity );
	return p;	

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	for each row in env.Items do
		p.Description = row.Item;
		Call ( "Catalogs.Items.Create", p );
	enddo;
		
	RegisterEnvironment ( id );
	
EndProcedure
