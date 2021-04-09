// Test writing record to info register "Producer price"
//
// 1. Creating env
// 2. Creating and Posting doc
// 3. testing movments

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6EA363" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create VendorInvoice
// *************************

p = Call ( "Documents.VendorInvoice.Create.Params" );
FillPropertyValues ( p, Env );
Call ( "Documents.VendorInvoice.Create", p );

form = With ( "Vendor Invoice*" );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
With ( "Records: Vendor Invoice*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Items", getItems ( ID ) );
	p.Insert ( "Vendor", "Vendor: " + ID );
	p.Insert ( "Warehouse", "Warehouse: " + ID );
	return p;

EndFunction

Function getItems ( ID )

	rows = new Array ();
	rows.Add ( rowItem ( "Item1: " + ID, 10, 100 ) );
	return rows;

EndFunction

Function rowItem ( Item, Quantity, Price, CountPackages = false )

	row = Call ( "Documents.ExpenseReport.Create.ItemsRow" );
	row.Item = Item;
	row.Quantity = Quantity;
	row.Price = Price;
	row.Social = true;
	row.ProducerPrice = Price + 50;
	row.Insert ( "CountPackages", CountPackages );
	return row;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Items
	// *************************
	
	for each row in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
		p.CountPackages = row.CountPackages;
		p.Social = true;
		Call ( "Catalogs.Items.Create", p );
	enddo;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Organization = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );

	Call ( "Common.StampData", id );
	
EndProcedure
