// Check the correct working of the AddFromInvoice button with the InvoicesInTable flag:
// - Create VendorInvoice
// - Create Invoice #1
// - Create Invoice #2
// - Create Return
// - Select Invoice #1
// - Select Invoice #2 
// - Post & CheckTemplate

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BDA751D" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create VendorInvoice
// *************************

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Vendor = env.Vendor;
p.Warehouse = env.Warehouse;
p.ID = id;
items = p.Items;
for each row in env.Items do
	newRow = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	FillPropertyValues ( newRow, row );
	newRow.Quantity = row.Quantity * 2;
	items.Add ( newRow );
enddo;
Call ( "Documents.VendorInvoice.Buy", p );

// *************************
// Create Invoice #1
// *************************

p = Call ( "Documents.Invoice.Sale.Params" );
p.Action = "Post";
p.Customer = env.Customer;
p.Warehouse = env.Warehouse;
items = p.Items; 
for each row in env.Items do
	newRow = Call ( "Documents.Invoice.Sale.ItemsRow" );
	FillPropertyValues ( newRow, row );
	newRow.Price = row.RetailPrice;
	items.Add ( newRow );
enddo;
form = Call ( "Documents.Invoice.Sale", p );
firstNumber = Fetch ( "#Number", form );

// *************************
// Create Invoice #2
// *************************

p = Call ( "Documents.Invoice.Sale.Params" );
p.Action = "Post";
p.Customer = env.Customer;
p.Warehouse = env.Warehouse;
items = p.Items; 
for each row in env.Items do
	newRow = Call ( "Documents.Invoice.Sale.ItemsRow" );
	FillPropertyValues ( newRow, row );
	newRow.Price = row.RetailPrice;
	items.Add ( newRow );
enddo;
form = Call ( "Documents.Invoice.Sale", p );
secondNumber = Fetch ( "#Number", form );

// ************************
// Create Return
// *************************

form = Commando ( "e1cib/command/Document.Return.Create" );
Set ( "#Customer", env.Customer );
Set ( "#Warehouse", env.Warehouse );

// *************************
// Select Invoice #1
// *************************

Click ( "#ItemsChoiceInvoice", form );
With ( "Invoices" );
list = Activate ( "#List" );
GotoRow ( list, "Number", firstNumber );
Click ( "#FormChoose" );
With ( "Items" );
Click ( "#FormSelect" );

// *************************
// Select Invoice #2
// *************************

Click ( "#ItemsChoiceInvoice", form );
With ( "Invoices" );
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
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Items", getItems ( ID ) );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "10.00", "20.00", "10" ) );
	list.Add ( getItem ( "Item2 " + ID, "20.00", "40.00", "20" ) );
	list.Add ( getItem ( "Item3 " + ID, "30.00", "60.00", "30" ) );
	return list;

EndFunction

Function getItem ( Description, Price, RetailPrice, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
	p.Insert ( "RetailPrice", RetailPrice );
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
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
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