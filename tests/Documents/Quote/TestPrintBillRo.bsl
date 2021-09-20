Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A861A" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.Quote" );
formMain = With ( "Quote (cr*" );
Put ( "#Company", Env.Company );
Put ( "#Customer", Env.Customer );
Put ( "#VATUse", "Excluded from Price" );

table = Get ( "#Services" );
Click ( "#ServicesAdd" );

Put ( "#ServicesItem", env.Item, table );
Put ( "#ServicesQuantity", 10, table );
Put ( "#ServicesPrice", 100, table );

Click ( "#ServicesAdd" );

Put ( "#ServicesItem", env.Item, table );
Put ( "#ServicesQuantity", 5, table );
Put ( "#ServicesPrice", 200, table );
Next ();
Click ( "#JustSave" );
Click ( "#FormDataProcessorBillBillRo" );
form = With ( "Invoice: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );
With ( formMain );
Run ( "TestPrintBillRu" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Service " + ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Customer", "Customer: " + ID );
	p.Insert ( "PaymentAddress", "Payment Address: " + ID );
	p.Insert ( "Bank", "Bank: " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
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
	
	// Complete Company
	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Env.Company;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Env.Company + "*" );
	Put ( "#CodeFiscal", "2000011111" );
	Put ( "#PaymentAddress", Env.PaymentAddress );
	Put ( "#BankAccount", Env.Bank );
	Click ( "#FormWriteAndClose" );
	
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