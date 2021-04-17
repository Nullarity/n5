Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AC167" );
env = getEnv ( id );
createEnv ( env );

// Last Report

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "5-CI 2015" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "12/31/2018" );
Put ( "#DateEnd", "12/31/2018" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R9C9:R9C17]", "Province: " + id );
Set ( "#ReportField[R11C4:R11C13]", "Street: " + id );
Set ( "#ReportField[R11C15:R11C17]", "Apartment: " + id );

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "5-CI 2015" );
Click ( "#FormChoose" );

With ( list );
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "05/01/2019" );
Put ( "#DateEnd", "05/01/2019" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R66C28:R66C44]", "550" );
Set ( "#ReportField[R79C28:R79C44]", "100" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Current", Date ( 2019, 5, 1 ) );
	p.Insert ( "Last", Date ( 2019, 1, 1 ) );
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
	Set ( "#ReportField[CUIO]", "CUIO: " + id );
	Set ( "#ReportField[Region]", "Region: " + id );
	Close ( form );
	
	// *************************
	// Report Details
	// *************************
	
	map = new Map ();
	addItemMap ( map, "0300", id );
	addItemMap ( map, "0310", id );
	addItemMap ( map, "0510", id );
	addItemMap ( map, "0540", id );
	addItemMap ( map, "0900", id );
	addItemMap ( map, "1010", id );
	addItemMap ( map, "1063", id );
	for each item in map do
		Call ( "Catalogs.Expenses.Create", item.Value );
	enddo;
	
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.ReportDetails" );
	for each item in map do
		With ( "Report Details" );
		Click ( "#FormCreate" );
		With ( "Report Details (create)" );
		Put ( "#Expense", item.Value );
		Put ( "#Row", item.Key );
		Put ( "#Report", "5-CI 2015" );
		Click ( "#FormWriteAndClose" );
	enddo;
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Current );
	p.Company = env.Company;
	p.Records.Add ( row ( "0", "6111", "6111" ) );
	p.Records.Add ( row ( "0", "6112", "6112" ) );
	p.Records.Add ( row ( "0", "6113", "6113" ) );
	p.Records.Add ( row ( "0", "6115", "6115" ) );
	p.Records.Add ( row ( "0", "6122", "0.22" ) );
	p.Records.Add ( row ( "0", "6121", "6121" ) );
	p.Records.Add ( row ( "7112", "0", "7112" ) );
	p.Records.Add ( row ( "2111", "0", "2111" ) );
	p.Records.Add ( row ( "2171", "0", "2171" ) );
	for each item in map do
		p.Records.Add ( row ( "7131", "0", item.Key, item.Value ) );
	enddo;
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Last );
	p.Company = env.Company;
	p.Records.Add ( row ( "2111", "0", "21110" ) );
	p.Records.Add ( row ( "2171", "0", "21710" ) );
	Call ( "Documents.Entry.Create", p );
	
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

Procedure addItemMap ( Map, Code, ID )
	
	Map.Insert ( Code, "Expense (" + code + "): " + ID );
	
EndProcedure

