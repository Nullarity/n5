// Test filling VendorReturn by AddFromInvoice button:
// - Create VendorInvoice
// - Create VendorReturn
// - Select VendorInvoice 
// - Post & CheckTemplate

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE6DA85" );
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
	items.Add ( newRow );
enddo;
number = Call ( "Documents.VendorInvoice.Buy", p ).Number;

// *************************
// Create VendorReturn
// *************************

Commando("e1cib/command/Document.VendorReturn.Create");
form = With ( "Return to Vendor (cr*" );
Set ( "#Vendor", env.Vendor );
Set ( "#Warehouse", env.Warehouse );
Set ( "#Memo", id );

// *************************
// Select VendorInvoice 
// *************************

Click ( "#ItemsChoiceInvoice", form );
With ( "Vendor Invoices" );
list = Activate ( "#List" );
GotoRow ( list, "Number", number );
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

Function createVendorInvoice ( Env )

	Commando("e1cib/command/Document.VendorInvoice.Create");
	form = With ( "Vendor Invoice (cr*" );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Memo", Env.ID );
	table = Activate ( "#ItemsTable" );
	for each row in Env.Items do
		Click ( "#ItemsTableAdd" );
		Put ( "#ItemsItem", row.Item, table );
		Put ( "#ItemsQuantity", row.Quantity, table );
		Put ( "#ItemsPrice", row.Price, table );
	enddo;
	Click ( "#FormPost", form );
	number = Fetch ( "#Number", form );
	Close ( form );
	return number;	

EndFunction


