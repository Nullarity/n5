Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6ABE49" );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report
// ***********************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Информация о доходах юридического лица" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Set ( "#ReportField[R2C9:R2C34]", Env.Vendor );

Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Code", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Vendor", "Vendor: " + ID );
	p.Insert ( "Date", "03/01/2019" );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	
	Call ( "Catalogs.Companies.Create", Env.Company );
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Put ( "#RegistrationNumber", "RegistrationNumber" );
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
	
	// *************************
	// Create Vendor
	// *************************
	
	Call ( "Catalogs.Organizations.CreateVendor", Env.Vendor );
	
	// *************************
	// Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "115000", Env.Vendor ) );
	p.Records.Add ( row ( "5211", "5343", "5000", Env.Vendor, "ALT" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "11000", Env.Vendor ) );
	p.Records.Add ( row ( "5211", "5343", "50", Env.Vendor, "ROY" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "1000", Env.Vendor ) );
	p.Records.Add ( row ( "5211", "5343", "5", Env.Vendor, "DIV a)" ) );
	Call ( "Documents.Entry.Create", p );
	
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.DeductionsClassifier" );
	With ( "Deductions" );
	Click ( "#ListContextMenuCreate" );
	form = With ( "Deductions (create)" );
	Put ( "#Code", "P" );
	Put ( "#Description", "P" );
	Click ( "#FormWriteAndClose" );
	if ( Waiting ( "1?:*" ) ) then
		With ( "1?:*" );
		Click ( "OK" );
		Close ( form );
		if ( Waiting ( "1?:*" ) ) then
			With ( "1?:*" );
			Click ( "No" );
		endif;
	endif;
	
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.DeductionRates" );
	With ( "Deduction Rates" );
	Click ( "#ListContextMenuCreate" );
	form = With ( "Deduction Rates (create)" );
	Put ( "#Period", "01/01/2019" );
	Put ( "#Rate", 2000 );
	Put ( "#Deduction", "P" );
	Click ( "#FormWriteAndClose" );
	if ( Waiting ( "1?:*" ) ) then
		With ( "1?:*" );
		Click ( "OK" );
		Close ( form );
		if ( Waiting ( "1?:*" ) ) then
			With ( "1?:*" );
			Click ( "No" );
		endif;
	endif;
	
	Call ( "Common.StampData", id );
	
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
