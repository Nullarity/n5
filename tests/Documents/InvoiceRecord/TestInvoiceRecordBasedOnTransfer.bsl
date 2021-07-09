// Creates InvoiceRecord from Transfer and check form InvoiceRecord
// 1. Create Transfer
// 2. Generate Invoice Record from Tranfer
// 3. Check Print form

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A82B3" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.InvoiceRecord" );
With ();

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );

Click ( "#ListContextMenuChange" );
form = With ();
Click ( "#FormPrint" );
With ();
Call ( "Common.CheckLogic", "#TabDoc" );
Close ();

With ( form );
CheckState ( "#Warning", "Visible" );

With ( form );
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
CheckState ( "#Warning", "Visible", false );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Sender", "Sender: " + ID );
	p.Insert ( "Receiver", "Receiver: " + ID );
	p.Insert ( "Loading", "Loading address: " + ID );
	p.Insert ( "PaymentAddress", "Payment Address: " + ID );
	p.Insert ( "Unloading", "Unloading address: " + ID );
	p.Insert ( "Bank", "Bank: " + ID );
	p.Insert ( "Dispetcher", "Dispetcher: " + ID );
	p.Insert ( "Keeper", "Keeper: " + ID );
	p.Insert ( "Item1", "Item1: " + ID );
	p.Insert ( "Item2", "Item2: " + ID );
	p.Insert ( "Carrier", "Carrier: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Carrier
	// *************************
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	Put ( "#Description", Env.Carrier );
	Click ( "#Vendor" );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Create Company
	// *************************
	Call ( "Catalogs.Companies.Create", Env.Company );
	
	// *************************
	// Create Warehouse
	// *************************
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Sender;
	p.Company = Env.Company;
	Call ( "Catalogs.Warehouses.Create", p );
	p.Description = Env.Receiver;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Bank
	// *************************
	p = Call ( "Catalogs.Banks.Create.Params" );
	p.Description = Env.Bank;
	p.Code = id;
	Call ( "Catalogs.Banks.Create", p );
	
	// *************************
	// Create BankAccounts
	// *************************
	p = Call ( "Catalogs.BankAccounts.Create.Params" );
	p.Company = Env.Company;
	p.Bank = Env.Bank;
	p.AccountNumber = "555222";
	Call ( "Catalogs.BankAccounts.Create", p );
	
	// *************************
	// Addresses
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.PaymentAddress );
	setValue ( "#Owner", Env.Company, "Companies" );
	Click ( "#FormWriteAndClose" );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.Loading );
	setValue ( "#Owner", Env.Sender, "Warehouses" );
	Click ( "#FormWriteAndClose" );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.Unloading );
	setValue ( "#Owner", Env.Receiver, "Warehouses" );
	Click ( "#FormWriteAndClose" );
	
	// Complete company
	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );

	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Env.Company;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Env.Company + "*" );
	Put ( "#CodeFiscal", "1000011111" );
	Put ( "#PaymentAddress", Env.PaymentAddress );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Dispetcher;
	Call ( "Catalogs.Employees.Create", p );
	
	p.Description = Env.Keeper;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Items
	// *************************
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
	p.Feature = "Feature";
	p.CountPackages = true;
	Call ( "Catalogs.Items.Create", p );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p );
		
	// *************************
	// Transfer
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Transfer" );
	With ( "Transfer (*" );
	Put ( "#Company", Env.Company );
	Put ( "#Sender", Env.Sender );
	Put ( "#Receiver", Env.Receiver );
	Click ( "#ShowPrices" );
	Put ( "#VATUse", "Excluded from Price" );
	table = Get ( "#ItemsTable" );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item1, table );
	Next ();

	Put ( "#ItemsFeature", "Feature", table );
	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 100, table );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item2, table );
	Next ();

	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 200, table );
	Click ( "#JustSave" );	
	With ( "Transfer*" );
	Click ( "#NewInvoiceRecord" );
	
	form = With ();
	Get ( "#Range" ).Clear ();
	Put ( "#Number", id );
	Put ( "#DeliveryDate", "03/25/2020" );
	Put ( "#Memo", id );
	Put ( "#Account", Env.Bank );
	Put ( "#WaybillSeries", "BB" );
	Put ( "#WaybillNumber", "881" );
	Put ( "#WaybillDate", "01/01/2017" );
	Pause (5);
	Choose ( "#Carrier" );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Organizations" );
	Click ( "#OK" );
	With ( "Organizations" );
	Close ( "Organizations" );
	With ( form );
	Put ( "#Carrier", Env.Carrier );
	Put ( "#LoadingAddress", Env.Loading );
	Put ( "#UnloadingAddress", Env.Unloading );
	Put ( "#PowerAttorneySeries", "X" );
	Put ( "#PowerAttorneyNumber", "71" );
	Put ( "#PowerAttorneyDate", "01/10/2018" );
	Put ( "#Delegated", "Delegated: " + ID );
	Put ( "#AttachedDocuments", "AttachedDocuments: " + ID );
	Put ( "#Dispatcher", Env.Dispetcher );
	Put ( "#Storekeeper", Env.Keeper );
	Put ( "#FirstPageRows", 1 );
	
	Click ( "#FormWriteAndClose" );
	
	RegisterEnvironment ( id );

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
