Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6EB6D1" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "IVAO15" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "03/31/2017" );
Put ( "#DateEnd", "03/31/2017" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes" );

With ( list );
Set ( "#ReportField[R64C90:R67C109]", "100" );
Set ( "#ReportField[R78C90:R81C109]", "10" );
Set ( "#ReportField[R86C90:R89C109]", "900" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Current", Date ( 2017, 3, 1 ) );
	p.Insert ( "Last", Date ( 2016, 3, 1 ) );
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
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Current );
	p.Company = env.Company;
	p.Records.Add ( row ( "0", "6111", "6111" ) );
	p.Records.Add ( row ( "0", "6112", "6112" ) );
	p.Records.Add ( row ( "0", "6121", "6121" ) );
	p.Records.Add ( row ( "0", "6124", "6124" ) );
	p.Records.Add ( row ( "0", "6122", "6122" ) );
	p.Records.Add ( row ( "0", "6125", "6125" ) );
	p.Records.Add ( row ( "0", "6115", "6115" ) );
	p.Records.Add ( row ( "0", "6123", "6123" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause (1);
	list = With ();
	Put ( "#CompanyFilter", env.Company );
	
	// Create Report
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	
	// Select period
	form = With ( "Значения по умолчанию" );
	Pause (1);
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[KindOfActivity]", "KindOfActivity: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function local ( Date1, Date2 = undefined, Date3 = undefined )
	
	if ( Date2 = undefined ) then
		date = Date1;
	else
		date = Date ( Date1, Date2, Date3 );
	endif;
	return Format ( date, "DLF = 'DT'" );
	
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