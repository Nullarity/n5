Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AAA06" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Last Report
// *************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "SERV TS 2014 (Rom)" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "12/31/2018" );
Put ( "#DateEnd", "12/31/2018" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes",);

With ( list );
Set ( "#ReportField[R6C9:R6C26]", "Province: " + env.ID );
Set ( "#ReportField[R7C5:R7C21]", "Street: " + env.ID );
Set ( "#ReportField[R7C24:R7C26]", "Apartment: " + env.ID );

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "SERV TS 2014 (Rom)" );
Click ( "#FormChoose" );

With ( list );
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "03/31/2019" );
Put ( "#DateEnd", "03/31/2019" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes",);

With ( list );
Set ( "#ReportField[R48C30:R48C34]", "100" );
Set ( "#ReportField[R49C30:R49C34]", "50" );
Set ( "#ReportField[R44C30:R44C34]", "10" );
Set ( "#ReportField[R61C30:R61C34]", "100" );
Set ( "#ReportField[R64C30:R64C34]", "50" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Current", Date ( 2019, 3, 1 ) );
	p.Insert ( "Last", Date ( 2018, 3, 1 ) );
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
	// Create Entrys
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Current );
	p.Company = env.Company;
	p.Records.Add ( row ( "0", "6111", "6111" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Last );
	p.Company = env.Company;
	p.Records.Add ( row ( "0", "6111", "61110" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause (1);
	With ();
	Put ( "#CompanyFilter", env.Company );
	
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	Pause ( __.Performance * 3 );
	
	form = With ( "Значения по умолчанию" );
	Set ( "#ReportField[CUIO]", "CUIO: " + id );
	Set ( "#ReportField[Region]", "Region: " + id );
	Close ( form );
	
	Call ( "Common.StampData", id );
	
EndProcedure

Function local ( Date1, Date2 = undefined, Date3 = undefined, Time = true )
	
	if ( Date2 = undefined ) then
		date = Date1;
	else
		date = Date ( Date1, Date2, Date3 );
	endif;
	return Format ( date, ? ( Time, "DLF = 'DT'", "DLF = 'D'" ) );
	
EndFunction

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined, DimCr1 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	row.DimCr1 = DimCr1;
	return row;
	
EndFunction