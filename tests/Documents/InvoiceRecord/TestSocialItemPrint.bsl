//1. Create Socially significant item
//2. Create Invoice
//2.1 add in tab. section socially significant item 
//3. test print form

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A82F3" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.InvoiceRecord" );
With ( "Invoice Records" );
p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = env.Number;
Call ( "Common.Find", p );

Click ( "#ListContextMenuChange" );
With ( "Invoice Record #*" );
Set ( "#Type", "Invoice" );
Click ( "#FormPrint" );
form = With ( "Invoice: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Warehouse", "Warehouse: " + ID );
	p.Insert ( "Customer", "Customer: " + ID );
	p.Insert ( "Loading", "Loading address: " + ID );
	p.Insert ( "PaymentAddress", "Payment Address: " + ID );
	p.Insert ( "Unloading", "Unloading address: " + ID );
	p.Insert ( "Bank", "Bank: " + ID );
	p.Insert ( "Dispetcher", "Dispetcher: " + ID );
	p.Insert ( "Driver", "Driver: " + ID );
	p.Insert ( "Keeper", "Keeper: " + ID );
	p.Insert ( "Item1", "Item1: " + ID );
	p.Insert ( "Item2", "Item2: " + ID );
	p.Insert ( "Carrier", "Carrier: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
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
	// Create Customer
	// *************************
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	Put ( "#Description", Env.Customer );
	Click ( "#Customer" );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Create Company
	// *************************
	Call ( "Catalogs.Companies.Create", Env.Company );
	
	// *************************
	// Create Warehouse
	// *************************
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	p.Company = Env.Company;
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
	setValue ( "#Owner", Env.Warehouse, "Warehouses" );
	Click ( "#FormWriteAndClose" );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.Unloading );
	setValue ( "#Owner", Env.Customer, "Organizations", "Name" );
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
	Click("#VAT");
	Put ( "#VATCode", "12518888" );
	Put ( "#PaymentAddress", Env.PaymentAddress );
	Click ( "#FormWriteAndClose" );
	
	// Complete Customer
	Commando ( "e1cib/list/Catalog.Organizations" );
	With ( "Organizations" );

	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = Env.Customer;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Env.Customer + "*" );
	Put ( "#CodeFiscal", "2000011111" );
	Put("#VATUse", "Included in Price");
	Put ( "#VATCode", "22518888" );
	Put ( "#ShippingAddress", Env.Unloading );
	Click ( "#FormWriteAndClose" );
	
	// Complete Carrier
	Commando ( "e1cib/list/Catalog.Organizations" );
	With ( "Organizations" );

	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = Env.Carrier;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Env.Carrier + "*" );
	Put ( "#CodeFiscal", "3000011111" );
	Put("#VATUse", "Included in Price");
	Put ( "#VATCode", "32518888" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Driver;
	Call ( "Catalogs.Employees.Create", p );
	
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
	p.Social = true;
	Call ( "Catalogs.Items.Create", p );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p );
		
	// *************************
	// Invoice
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Invoice" );
	With ( "Invoice (*" );
	Put ( "#Company", Env.Company );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Customer", Env.Customer );
	Put ( "#VATUse", "Excluded from Price" );
	Put ( "#Currency", "MDL" );
	Put ( "#Date", "08/14/2017" );
	table = Get ( "#ItemsTable" );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item1, table );
	Next ();

	Put ( "#ItemsFeature", "Feature", table );
	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 100, table );
	Set ( "#ItemsProducerPrice", 50, table );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item2, table );
	Next ();

	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 200, table );
	Click ( "#JustSave" );	
	With ( "Invoice*" );
	Click ( "#NewInvoiceRecord" );
	
	form = With ( "Invoice Record*" );
	Get ( "#Range" ).Clear ();
	Put ( "#Number", "AA" + id );
	Put ( "#Account", Env.Bank );
	Put ( "#WaybillSeries", "BB" );
	Put ( "#WaybillNumber", "881" );
	Put ( "#WaybillDate", "01/01/2017" );
	Choose ( "#Carrier" );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Organizations" );
	Click ( "#OK" );
	With ( "Organizations" );
	Close ( "Organizations" );
	With ( form );
	Put ( "#Carrier", Env.Carrier );
	Put ( "#Driver", Env.Driver );
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
	Put ( "#Redirects", "Redirects" );
	Put ( "#DeliveryDate", "08/14/2017" );
	Click ( "#FormWrite" );
	Env.Insert ( "Number", Fetch ( "#Number" ) );
	Close ( form );
	
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
