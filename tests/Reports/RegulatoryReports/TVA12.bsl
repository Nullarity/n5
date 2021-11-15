Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8D11AC" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Current Report
// *************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause ( __.Performance * 3 );
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Декларация по НДС" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "01/01/2019" );
Put ( "#DateEnd", "01/31/2019" );
Click ( "#Select" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Vendor", "Vendor: " + ID );
	p.Insert ( "Customer", "Customer: " + ID );
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
	// Create Roles
	// *************************
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Addresses
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", "Payment Address" );
	setValue ( "#Owner", Env.Company, "Companies" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Env.Company;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Put ( "#PaymentAddress", "Payment Address" );
	Click("#VAT");
	Put ( "#VATCode", "222555" );
	Put ( "#RegistrationDate", "01/10/2015" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Vendor
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Put ( "#Description", Env.Vendor );
	Put ( "#CodeFiscal", "10000111" );
	Click ( "#Vendor" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Customer
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Put ( "#Description", Env.Customer );
	Put ( "#CodeFiscal", "10000222" );
	Click ( "#Customer" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create VATPurchase
	// *************************
	
	Commando ( "e1cib/data/Document.VATPurchases" );
	With ( "VAT on Purchases (cr*" );
	Put ( "#Date", "01/01/2019" );
	Put ( "#Company", Env.Company );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Series", "AA" );
	Put ( "#FormNumber", id + "1" );
	Put ( "#RecordDate", "01/01/2019" );
	Put ( "#Amount", "1000" );
	Put ( "#VATCode", "20%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATPurchases" );
	With ( "VAT on Purchases (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "01/02/2019" );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Series", "AA" );
	Put ( "#FormNumber", id + "2" );
	Put ( "#RecordDate", "01/02/2019" );
	Put ( "#Amount", "2000" );
	Put ( "#VATCode", "8%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATPurchases" );
	With ( "VAT on Purchases (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "01/03/2019" );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Series", "AA" );
	Put ( "#FormNumber", id + "3" );
	Put ( "#RecordDate", "01/03/2019" );
	Put ( "#Amount", "100" );
	Put ( "#VATCode", "0%" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create VATSale
	// *************************
	
	Commando ( "e1cib/data/Document.VATSales" );
	With ( "VAT on Sales (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "01/01/2019" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Series", "BB" );
	Put ( "#FormNumber", id + "1" );
	Put ( "#RecordDate", "01/01/2019" );
	Put ( "#Amount", "1000" );
	Put ( "#VATCode", "20%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATSales" );
	With ( "VAT on Sales (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "01/02/2019" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Series", "BB" );
	Put ( "#FormNumber", id + "2" );
	Put ( "#RecordDate", "01/02/2019" );
	Put ( "#Amount", "1000" );
	Put ( "#VATCode", "0%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATSales" );
	With ( "VAT on Sales (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "01/03/2019" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Series", "BB" );
	Put ( "#FormNumber", id + "3" );
	Put ( "#RecordDate", "01/03/2019" );
	Put ( "#Amount", "600" );
	Put ( "#VATCode", "8%" );
	Click ( "#FormWriteAndClose" ); 
	
	// *************************
	// Advance
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = "01/01/2019";
	p.Company = env.Company;
	p.Records.Add ( row ( "2252", "2421", "1000" ) );
	Call ( "Documents.Entry.Create", p );
	
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

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined, DimCr1 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	row.DimCr1 = DimCr1;
	return row;
	
EndFunction

