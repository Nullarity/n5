Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6ABD42" );
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
GotoRow ( "#List", "Description", "BASS" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R45C25:R45C30]", "100" );
Set ( "#ReportField[R71C19:R72C22]", "50" );
Set ( "#ReportField[R67C19:R68C22]", "15" );
Set ( "#ReportField[R73C28:R74C32]", "300" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Date", "01/01/2019" );
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
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	Clear ( "#UnitFilter" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	
	With ( env.Company + " (Companies)" );
	Put ( "#CodeFiscal", "1000101552352" );
	Put ( "#RegistrationNumber", "Registration Number" );
	Click ( "#FormWrite" );
	Click ( "Contacts", GetLinks () );
	
	With ( env.Company + " (Companies)" );
	Click ( "Addresses", GetLinks () );
	With ( env.Company + " (Companies)" );
	Click ( "#FormCreate" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", "Address: " + id );
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
	// Create Compensation
	// *************************
	
	salary = "Hourly Rate" + id;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = salary;
	Call ( "CalculationTypes.Compensations.Create", p );	
	
	sick = "Sick Days" + id;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = sick;
	p.Method = "Sick Days";
	Call ( "CalculationTypes.Compensations.Create", p );	
	
	// *************************
	// Create Social Insurance
	// *************************
	
	tax = "Social Insurance" + id;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = tax;
	p.Account = "5331";
	p.Method = "Social Insurance";
	Call ( "CalculationTypes.Taxes.Create", p );
	
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause (1);
	list = With ();
	Put ( "#CompanyFilter", env.Company );
	
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	
	form = With ( "Значения по умолчанию" );
	Pause (1);
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[CNAS]", "CNAS: " + id );
	Close ( form );
	
	// *************************
	// Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "7141", "5311", "10000", salary ) );
	p.Records.Add ( row ( "7141", "5331", "600" ) );
	p.Records.Add ( row ( "2264", "5311", "559" ) );
	p.Records.Add ( row ( "5331", "5311", "800", sick ) );
	p.Records.Add ( row ( "7141", "5311", "600", sick ) );
	Call ( "Documents.Entry.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function row ( AccountDr, AccountCr, Amount, DimCr2 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimCr2 = DimCr2;
	return row;
	
EndFunction
