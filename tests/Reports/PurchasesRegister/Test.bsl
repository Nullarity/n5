Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BAADAE3" );
env = getEnv ( id );
createEnv ( env );

make ( "01/01/2017", "03/31/2017", env );
Call ( "Common.CheckLogic", "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Vendor", "Vendor: " + id );
	p.Insert ( "Item20", "Item20: " + id );
	p.Insert ( "Item6", "Item6: " + id );
	p.Insert ( "Warehouse", "Warehouse: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists(id) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	Call ( "Catalogs.Companies.Create", Env.Company );
	
	// *************************
	// Create Warehouse
	// *************************
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Company = Env.Company;
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Roles
	// *************************
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Create Vendor
	// *************************
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Put ( "#Description", Env.Vendor );
	Put ( "#CodeFiscal", "10000111" );
	Put ( "#VATUse", "Excluded from Price" );
	Click ( "#Vendor" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );
	form = With ( Env.Vendor + "* " );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Put ( "#Company", Env.Company );
	Click ( "#FormWriteAndClose" );
	
	Close ( form );
	
	// *************************
	// Create Item
	// *************************
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item20;
	Call ( "Catalogs.Items.Create", p );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item6;
	p.VAT = "6%";
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Vendor Invoice
	// *************************
	Commando ( "e1cib/data/Document.VendorInvoice" );
	With ( "Vendor Invoice (create)" );
	Put ( "#Date", "01/01/2017" );
	Put ( "#Company", Env.Company );
	Put ( "#ReferenceDate", "03/13/2017" );
	Put ( "#Series", "AB" );
	Put ( "#Reference", "005" + id );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Vendor", Env.Vendor );
	
	// Items
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item20, table );
	Put ( "#ItemsQuantityPkg", 1, table );
	Put ( "#ItemsPrice", 100, table );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item6, table );
	Put ( "#ItemsQuantityPkg", 1, table );
	Put ( "#ItemsPrice", 100, table );
	
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create VAT Purchase
	// *************************
	Commando ( "e1cib/data/Document.VATPurchases" );
	With ( "VAT on Purchases (cr*" );
	Put ( "#Date", "03/01/2017" );
	Put ( "#Company", Env.Company );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Series", "AA" );
	Put ( "#FormNumber", "00001" + id );
	Put ( "#Date", "01/01/2017" );
	Put ( "#Amount", "1000" );
	Put ( "#VATCode", "20%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATPurchases" );
	With ( "VAT on Purchases (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "03/02/2017" );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Series", "AA" );
	Put ( "#FormNumber", "00007" + id );
	Put ( "#Date", "01/05/2017" );
	Put ( "#Amount", "2000" );
	Put ( "#VATCode", "6%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATPurchases" );
	With ( "VAT on Purchases (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "03/03/2017" );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Series", "AA" );
	Put ( "#FormNumber", "00002" + id );
	Put ( "#Date", "01/02/2017" );
	Put ( "#Amount", "100" );
	Put ( "#VATCode", "0%" );
	Click ( "#FormWriteAndClose" );
	
	RegisterEnvironment(id);

EndProcedure

Procedure make ( Date1, Date2, Env )

	p = Call ( "Common.Report.Params" );
	p.Path = "Accounting / Purchases Register";
	p.Title = "Purchases Register*";
	filters = new Array ();

	item = Call ( "Common.Report.Filter" );
	item.Name = "Company";
	item.Value = env.Company;
	filters.Add ( item );
	
	item = Call ( "Common.Report.Filter" );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date1;
	item.ValueTo = Date2;
	filters.Add ( item );

	

	p.Filters = filters;
	
	form = With ( Call ( "Common.Report", p ) );

EndProcedure

