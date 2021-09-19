Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A5F75B5" );
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
GotoRow ( "#List", "Description", "Med 08" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "_Company: " + ID );
	p.Insert ( "Date", "03/01/2019" );
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
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Compensation
	// *************************
	
	salary = "Hourly Rate" + id;
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = salary;
	Call ( "CalculationTypes.Compensations.Create", p );	
	
	// *************************
	// Create Medical Insurance
	// *************************
	
	tax = "Medical Insurance" + id;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = tax;
	p.Account = "5332";
	p.Method = "Medical Insurance";
	Call ( "CalculationTypes.Taxes.Create", p );	
	
	// *************************
	// Taxes
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/ChartOfCalculationTypes.Taxes" );
	With ( "Taxes" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = tax;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	form = With ( "Medical Insurance*" );
	Click ( "#PayrollTaxesContextMenuCreate" );
	With ( "Payroll Taxes (create)" );
	Put ( "#Period", "01/2019" );
	Put ( "#Rate", "4.5" );
	Click ( "#FormWriteAndClose" );
	With ( form );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "7141", "5311", "10000", , salary ) );
	p.Records.Add ( row ( "7141", "5311", "10000" ) );
	p.Records.Add ( row ( "7141", "5412", "400" ) );
	p.Records.Add ( row ( "5412", "5332", "400" ) );
	p.Records.Add ( row ( "5311", "5332", "350", salary ) );
	p.Records.Add ( row ( "5311", "2411", "9000", salary ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// EmployeesOtherDebt
	// *************************
	
	Call ( "Reports.RegulatoryReports.EmployerOtherDebt" );
		
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
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration" );
	Set ( "#ReportField[Region]", "Region" );
	Set ( "#ReportField[CUATM]", "CUATM" );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function row ( AccountDr, AccountCr, Amount, DimDr2 = undefined, DimCr2 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr2 = DimDr2;
	row.DimCr2 = DimCr2;
	return row;
	
EndFunction
