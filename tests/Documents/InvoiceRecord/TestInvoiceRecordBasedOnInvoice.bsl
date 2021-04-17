Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "2B8A84B8");
env = getEnv(id);
createEnv(env);

Commando("e1cib/list/Document.InvoiceRecord");
With("Invoice Records");

p = Call("Common.Find.Params");
p.Where = "Memo";
p.What = id;
Call("Common.Find", p);

Click("#ListContextMenuChange");
With("Invoice Record #*");
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
Set("#Type", "Invoice");

if (Fetch("#PrintBack") = "Yes") then
	Click("#PrintBack");
endif;

if (Fetch("#Transfer") = "Yes") then
	Click("#Transfer");
endif;

Put("#Redirects", "Redirects");

Click("#FormPrint");
form = With("Invoice: Print");
Call("Common.CheckLogic", "#TabDoc");
Close(form);

Run("TestInvoiceLandscape");
Run("TestInvoiceElectronic");
Run("TestInvoiceElectronicLandscape");

// *************************
// Procedures
// *************************

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Company", "Company: " + ID);
	p.Insert("Warehouse", "Warehouse: " + ID);
	p.Insert("Customer", "Customer: " + ID);
	p.Insert("Loading", "Loading address: " + ID);
	p.Insert("PaymentAddress", "Payment Address: " + ID);
	p.Insert("Unloading", "Unloading address: " + ID);
	p.Insert("Bank", "Bank: " + ID);
	p.Insert("Dispetcher", "Dispetcher: " + ID);
	p.Insert("Driver", "Driver: " + ID);
	p.Insert("Keeper", "Keeper: " + ID);
	p.Insert("Item1", "Item1: " + ID);
	p.Insert("Item2", "Item2: " + ID);
	p.Insert("Carrier", "Carrier: " + ID);
	prexix = Right(ID, 5);
	p.Insert("FormPrefix", prexix);
	p.Insert("Range", "Invoice Records " + prexix);
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Carrier
	// *************************
	
	Commando("e1cib/data/Catalog.Organizations");
	With("Organizations (create)");
	Put("#Description", Env.Carrier);
	Click("#Vendor");
	Click("#FormWriteAndClose");
	
	// *************************
	// Create Company
	// *************************
	
	Call ( "Catalogs.Companies.Create", Env.Company);
	
	// *************************
	// Create Customer
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	form = With( "Organizations (cr*" );
	Put ( "#Description", Env.Customer );
	Click ( "#Customer" );
	Click ( "#FormWrite" );
	Get ( "#CustomerPage" ).Expand ();
	field = Activate ( "#CustomerContract" );
	field.Open (); 
	With ( "*(Contracts)" );
	Put ( "#Company", Env.Company );
	Click ( "#FormWriteAndClose" );
	Close ( form );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params");
	p.Description = Env.Warehouse;
	p.Company = Env.Company;
	Call ( "Catalogs.Warehouses.Create", p);
	
	// *********************
	// Create Range
	// *********************
	
	Commando("e1cib/command/Catalog.Ranges.Create");
	Set("#Type", "Invoice Records");
	Set("#Prefix", env.FormPrefix);
	Set("#Start", 1);
	Set("#Finish", 50);
	Set("#Length", 3);
	Set("#Company", Env.Company);
	Click("#WriteAndClose");
	
	// *********************
	// Enroll Range
	// *********************
	
	Commando ( "e1cib/command/Document.EnrollRange.Create" );
	Put("#Date", "01/01/2017");
	Put ( "#Company", Env.Company );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Range", "Invoice Records " + env.FormPrefix );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Bank
	// *************************
	
	p = Call ( "Catalogs.Banks.Create.Params");
	p.Description = Env.Bank;
	p.Code = id;
	Call ( "Catalogs.Banks.Create", p);
	
	// *************************
	// Create BankAccounts
	// *************************
	
	p = Call ( "Catalogs.BankAccounts.Create.Params");
	p.Company = Env.Company;
	p.Bank = Env.Bank;
	p.AccountNumber = "555222";
	Call ( "Catalogs.BankAccounts.Create", p);
	
	// *************************
	// Create Addresses
	// *************************
	
	MainWindow.ExecuteCommand("e1cib/Data/Catalog.Addresses");
	With("Addresses (create)");
	Click("#Manual");
	Put("#Address", Env.PaymentAddress);
	setValue("#Owner", Env.Company, "Companies");
	Click("#FormWriteAndClose");
	
	MainWindow.ExecuteCommand("e1cib/Data/Catalog.Addresses");
	With("Addresses (create)");
	Click("#Manual");
	Put("#Address", Env.Loading);
	setValue("#Owner", Env.Warehouse, "Warehouses");
	Click("#FormWriteAndClose");
	
	MainWindow.ExecuteCommand("e1cib/Data/Catalog.Addresses");
	With("Addresses (create)");
	Click("#Manual");
	Put("#Address", Env.Unloading);
	setValue("#Owner", Env.Customer, "Organizations", "Name");
	Click("#FormWriteAndClose");
	
	// *************************
	// Complete Company
	// *************************
	
	Commando("e1cib/list/Catalog.Companies");
	With("Companies");
	
	p = Call("Common.Find.Params");
	p.Where = "Description";
	p.What = Env.Company;
	Call("Common.Find", p);
	Click("#ListContextMenuChange");
	With(Env.Company + "*");
	Put("#CodeFiscal", "1000011111");
	Click("#VAT");
	Put("#VATCode", "12518888");
	Put("#PaymentAddress", Env.PaymentAddress);
	Click("#FormWriteAndClose");
	
	// *************************
	// Complete Customer
	// *************************
	
	Commando("e1cib/list/Catalog.Organizations");
	With("Organizations");
	
	p = Call("Common.Find.Params");
	p.Where = "Name";
	p.What = Env.Customer;
	Call("Common.Find", p);
	Click("#ListContextMenuChange");
	With(Env.Customer + "*");
	Put("#CodeFiscal", "2000011111");
	Put("#VATUse", "Included in Price");
	Put("#VATCode", "22518888");
	Put("#ShippingAddress", Env.Unloading);
	Click("#FormWriteAndClose");
	
	// *************************
	// Complete Carrier
	// *************************
	
	Commando("e1cib/list/Catalog.Organizations");
	With("Organizations");
	
	p = Call("Common.Find.Params");
	p.Where = "Name";
	p.What = Env.Carrier;
	Call("Common.Find", p);
	Click("#ListContextMenuChange");
	With(Env.Carrier + "*");
	Put("#CodeFiscal", "3000011111");
	Put("#VATUse", "Included in Price");
	Put("#VATCode", "32518888");
	Click("#FormWriteAndClose");
	
	// *************************
	// Create Employees
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params");
	p.Description = Env.Driver;
	Call ( "Catalogs.Employees.Create", p);
	
	p.Description = Env.Dispetcher;
	Call ( "Catalogs.Employees.Create", p);
	
	p.Description = Env.Keeper;
	Call ( "Catalogs.Employees.Create", p);
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item1;
	p.Feature = "Feature";
	p.CountPackages = true;
	Call ( "Catalogs.Items.Create", p);
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p);
	
	// *************************
	// Create Invoice
	// *************************
	
	MainWindow.ExecuteCommand("e1cib/Data/Document.Invoice");
	With("Invoice (*");
	Put("#Company", Env.Company);
	Put("#Warehouse", Env.Warehouse);
	Put("#Customer", Env.Customer);
	Put("#VATUse", "Excluded from Price");
	Put("#Currency", "MDL");
	Put("#Date", "08/14/2017");
	table = Get("#ItemsTable");
	
	Click("#ItemsTableAdd");
	
	Put("#ItemsItem", env.Item1, table);
	Next();
	
	Put("#ItemsFeature", "Feature", table);
	Set("#ItemsQuantity", 1, table);
	Set("#ItemsPrice", 100, table);
	
	Click("#ItemsTableAdd");
	
	Put("#ItemsItem", env.Item2, table);
	Next();
	
	Set("#ItemsQuantity", 1, table);
	Set("#ItemsPrice", 200, table);
	Click("#JustSave");
	
	// *************************
	// Create Invoice Record
	// *************************
	
	Click("#NewInvoiceRecord");
	form = With("Invoice Record*");
	Choose ( "#Range" );
	With ();
	GotoRow("#List", "Range", Env.Range + " 1 - 50");
	Click ( "#FormChoose" );
	With();
	Set("#Memo", Env.ID);
	Put("#Account", Env.Bank);
	Put("#WaybillSeries", "BB");
	Put("#WaybillNumber", "881");
	Put("#WaybillDate", "01/01/2017");
	Choose("#Carrier");
	With("Select data type");
	GotoRow("#TypeTree", "", "Organizations");
	Click("#OK");
	With("Organizations");
	Close("Organizations");
	With(form);
	Put("#Carrier", Env.Carrier);
	Put("#Driver", Env.Driver);
	Put("#LoadingAddress", Env.Loading);
	Put("#UnloadingAddress", Env.Unloading);
	Put("#PowerAttorneySeries", "X");
	Put("#PowerAttorneyNumber", "71");
	Put("#PowerAttorneyDate", "01/10/2018");
	Put("#Delegated", "Delegated: " + ID);
	Put("#AttachedDocuments", "AttachedDocuments: " + ID);
	Put("#Dispatcher", Env.Dispetcher);
	Put("#Storekeeper", Env.Keeper);
	Put("#FirstPageRows", 1);
	Put("#Redirects", "Redirects");
	Put("#DeliveryDate", "08/14/2017");
	Click("#FormWriteAndClose");
	
	RegisterEnvironment(id);
	
EndProcedure

Procedure setValue(Field, Value, Object, GoToRow = "Description")
	
	form = CurrentSource;
	Choose(Field);
	With("Select data type");
	GotoRow("#TypeTree", "", Object);
	Click("#OK");
	if (Object = "Companies") then
		With("Addresses*");
		Put("#Owner", Value);
	else
		With(Object);
		GotoRow("#List", GoToRow, Value);
		Click("#FormChoose");
		CurrentSource = form;
	endif;
	
EndProcedure
