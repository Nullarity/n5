Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A6C851B" );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report
// ***********************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause ( __.Performance * 3 );
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "REV9" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
Click ( "Yes", DialogsTitle );

With ( list );
Set ( "#ReportField[F00203]", "100" );

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
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = "Hourly Rate" + id;
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
	
	tax = "Social Insurance (employee)" + id;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = tax;
	p.Account = "5333";
	p.Method = "Social Insurance (Employees)";
	Call ( "CalculationTypes.Taxes.Create", p );	
	
	// *************************
	// Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "7141", "5311", "10000" ) );
	p.Records.Add ( row ( "7141", "5331", "600" ) );
	p.Records.Add ( row ( "5311", "5333", "500" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause ( __.Performance * 3 );
	Put ( "#CompanyFilter", env.Company );
	
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	Pause ( __.Performance * 3 );
	
	form = With ( "Значения по умолчанию" );
	Set ( "#ReportField[Region]", "Region: " + id );
	Set ( "#ReportField[CNAS]", "CNAS: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
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
