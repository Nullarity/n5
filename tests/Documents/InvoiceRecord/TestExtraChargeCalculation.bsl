// Test calculation Extra Charge
//
// 1. Creating VendorInvoice with producer price
// 2. Creating invoice record
// 3. testing calculaiton extracharge = ( price - producer price ) / producer price * 100

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27C933F2" );
env = getEnv ( " " + id );
createEnv ( env );

// *************************
// Create Invoice Record
// *************************

Commando ( "e1cib/data/Document.InvoiceRecord" );
form = With ( "Invoice Record (cr*" );

setValue ( "#Customer", env.Customer, "Organizations", "Name" );
//Put ( "#Customer", env.Customer );
Put ( "#Date", "01/01/3999" );

// Items
table = Get ( "#Items" );
Click ( "#ItemsAdd" );

setValue ( "#ItemsItem", env.Item, "Items" );
 
Put ( "#ItemsQuantityPkg", 2, table );
Put ( "#ItemsPrice", 200, table );
Check ( "#ItemsExtraCharge", 66.67, table );

Click ( "#ItemsContextMenuDelete" );

// Test selection
Click ( "#ItemsSelectItems" );
selection = With ( "Items Selection" );

if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;

Pick ( "#Filter", "None" );

// *************************************
// Enable prices
// *************************************

flag = Fetch ( "#ShowPrices" );
if ( flag = "No" ) then
	Click ( "#ShowPrices" );
endif;

// *************************************
// Search Item
// *************************************

p = Call ( "Common.Find.Params" );
p.Where = "Item";
p.What = env.Item;
p.Button = "#ItemsListContextMenuFind";
Call ( "Common.Find", p );

table = Get ( "#ItemsList" );
table.Choose ();

table = Get ( "#FeaturesList" );
table.Choose ();

details = With ( "Details" );
Put ( "#QuantityPkg", 2 );
Put ( "#Price", 200 );
Next ();
Check ( "#ExtraCharge", 66.67 );

Click ( "#FormOK" );

With ( selection );
Click ( "#FormOK" );

With ( form );
table = Get ( "#Items" );
Check ( "#ItemsExtraCharge", 66.67, table );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "_Item1: " + ID );
	p.Insert ( "Items", getItems ( p.Item, ID ) );
	p.Insert ( "Vendor", "Vendor: " + ID );
	p.Insert ( "Customer", "Customer: " + ID );
	p.Insert ( "Department", "Department " + ID );
	return p;

EndFunction

Function getItems ( Item, ID )

	rows = new Array ();
	rows.Add ( rowItem ( Item, 10, 100 ) );
	return rows;

EndFunction

Function rowItem ( Item, Quantity, Price, CountPackages = false )

	row = Call ( "Documents.ExpenseReport.Create.ItemsRow" );
	row.Item = Item;
	row.Quantity = Quantity;
	row.Price = Price;
	row.ProducerPrice = Price;
	row.Social = true;
	row.Insert ( "CountPackages", CountPackages );
	return row;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Items
	// *************************
	
	for each row in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
		p.CountPackages = row.CountPackages;
		p.Social = row.Social;
		Call ( "Catalogs.Items.Create", p );
	enddo;
	
	// *************************
	// Create Vendor
	// *************************
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Organization = Env.Vendor;
	p.Currency = "CAD";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Customer
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Click ( "#Customer" );
	Put ( "#Description", Env.Customer );
	Put ( "#VATUse", "Excluded from Price" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create VendorInvoice
	// *************************
	p = Call ( "Documents.VendorInvoice.Create.Params" );
	FillPropertyValues ( p, Env );
	Call ( "Documents.VendorInvoice.Create", p );

	
	form = With ( "Vendor Invoice*" );
	Click ( "#FormPost" );


	Call ( "Common.StampData", id );
	
EndProcedure

Procedure setValue ( Field, Value, Object, GoToRow = "Description" )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", Object );
	Click ( "#OK" );
	if ( Object = "Companies" ) then
		With ( "Addresses*" );
		Put ( "#Owner", Value );
	else
		With ( Object );
		GotoRow ( "#List", GoToRow, Value );
		Click ( "#FormChoose" );
		CurrentSource = form;
	endif;
	
EndProcedure
