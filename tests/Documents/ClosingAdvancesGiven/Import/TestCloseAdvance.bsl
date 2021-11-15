// Create Closing Advances Given (Closing given advances operation) (USD) and check movements
// 1. create Payment
// 2. create closing advances given = given advance
// 3. create Vendor Invoice
// 4. create closeing advances and check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28A850B3" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Closing Advances
// *************************

MainWindow.ExecuteCommand ( "e1cib/list/DocumentJournal.Calculations" );
With ();
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
Try
	Click ( "#FormChange" );
	form = With ();
	try
		Click ( "#FormUndoPosting" )
	except
	endtry;
Except
	Click ( "#FormCreateByParameterClosingAdvancesGiven" );
	form = With ();
EndTry;

Put ( "#Date", "02/28/2017" );
Put ( "#Memo", id );
Put ( "#Company", Env.Company );
Click ( "#AdvancesFill" );

With ( "Closing Advances Given: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Vendor Account" );
table.ChangeRow ();
Put ( "#UserSettingsValue", "5212", table );
table.EndEditRow ();

GotoRow ( table, "Setting", "Vendor" );
table.ChangeRow ();
Put ( "#UserSettingsValue", env.Vendor, table );
table.EndEditRow ();

Click ( "#FormFill" );
Waiting ( form );
With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Closing Advances Given*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item: " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Company", "Company " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	p = Call ( "Catalogs.Companies.Create.Params" );
	p.Description = Env.Company;
	Call ( "Catalogs.Companies.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	p.Company = Env.Company;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Set Advance Account
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.OrganizationAccounts" );
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Company", Env.Company );
	Put ( "#AdvanceGiven", "2242" );
	Put ( "#AdvanceTaken", "2242" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Vendor
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	form = With ( "Organizations (create)" );
	Put ( "#Description", Env.Vendor );
	Click ( "#Vendor" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );
	With ( "Contracts" );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Put ( "#Currency", "USD" );
	Click ( "#Import" );
	Put ( "#Company", Env.Company );
	
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Vendor Payment
	// *************************
	
	Commando ( "e1cib/data/Document.VendorPayment" );
	With ( "Vendor Payment (create)" );
	Put ( "#Date", "01/01/2017" );
	Put ( "#Company", Env.Company );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Amount", "100" );
	Put ( "#Currency1", "USD" );
	Put ( "#Rate", "18" );
	Put ( "#Account", "2422" );
	Put ( "#VendorAccount", "5212" ); 
	Put ( "#AdvanceAccount", "5212" ); 
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Closing Advances Given
	// *************************

	Commando ( "e1cib/data/Document.ClosingAdvancesGiven" );
	form = With ( "Closing Advances Given (create)" );
	Put ( "#Date", "01/31/2017" );
	Put ( "#Company", Env.Company );
	Click ( "#AdvancesFill" );

	With ( "Closing Advances Given: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Vendor Account" );
	table.ChangeRow ();
	Put ( "#UserSettingsValue", "5212", table );
	table.EndEditRow ();

	GotoRow ( table, "Setting", "Vendor" );
	table.ChangeRow ();
	Put ( "#UserSettingsValue", env.Vendor, table );
	table.EndEditRow ();
	Click ( "#FormFill" );
	Waiting ( form );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Item
	// *************************
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Vendor Invoice
	// *************************
	Commando ( "e1cib/data/Document.VendorInvoice" );
	form = With ( "Vendor Invoice (create)" );
	Put ( "#Date", "02/01/2017" );	
	Put ( "#Company", Env.Company );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#VendorAccount", "5212" ); 
	Put ( "#Currency", "USD" );
	Put ( "#Rate", "19" );
	
	if ( Fetch ( "#CloseAdvances" ) = "Yes" ) then
		Click ( "#CloseAdvances" );
	endif;
	
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item );
	Next ();

	Set ( "#ItemsQuantity", 2, table );
	Set ( "#ItemsPrice", 50, table );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );

EndProcedure

