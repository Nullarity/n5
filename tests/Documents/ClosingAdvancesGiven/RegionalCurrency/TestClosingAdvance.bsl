// Create Closing Advances Given (Closing given advances operation) (MDL) and check movements
// 1. create Payment
// 2. create closing advances given = given advance
// 3. create Vendor Invoice
// 4. create closeing advances and check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A4E42C8" );
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
Put ( "#Company", Env.Company );
Put ( "#Memo", id );
Click ( "#AdvancesFill" );

With ( "Closing Advances Given: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Vendor Account" );
table.ChangeRow ();
Put ( "#UserSettingsValue", "5211", table );
table.EndEditRow ();
GotoRow ( table, "Setting", "Vendor" );
table.ChangeRow ();
Put ( "#UserSettingsValue", env.Vendor, table );
table.EndEditRow ();

Click ( "#FormFill" );
Pause ( __.Performance * 5 );

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
	p.Insert ( "Company", "Company " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Item", "Item " + ID );
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
	
	Call ( "Catalogs.Companies.Create", Env.Company );
	
	// *************************
	// Set Advance Account
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.OrganizationAccounts" );
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Company", Env.Company );
	Put ( "#AdvanceGiven", "2241" );
	Put ( "#AdvanceTaken", "5231" );
	Put ( "#VendorAccount", "5211" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Warehouse
	// *************************
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	p.Company = Env.Company;
	Call ( "Catalogs.Warehouses.Create", p );
	
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
	Put ( "#Currency1", "MDL" );
	Put ( "#Account", "2421" );
	Put ( "#AdvanceAccount", "5211" );
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
	Put ( "#UserSettingsValue", "5211", table );
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
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Warehouse", Env.Warehouse );
	
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

