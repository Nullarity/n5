Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A6C8498" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Last Report
// *************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause ( __.Performance * 3 );
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Сбор за воду" );
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
Click ( "Yes", DialogsTitle );

With ( list );
Set ( "#ReportField[R24C45:R24C56]", "100" );
Set ( "#ReportField[R24C57:R24C69]", "6" );
Set ( "#ReportField[R25C45:R26C56]", "20" );
Set ( "#ReportField[R25C57:R26C69]", "5" );

// *************************
// Current Report
// *************************

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Сбор за воду" );
Click ( "#FormChoose" );

With ( list );
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "03/31/2019" );
Put ( "#DateEnd", "03/31/2019" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
Click ( "Yes", DialogsTitle );

With ( list );
Set ( "#ReportField[R24C35:R24C44]", "20" );
Set ( "#ReportField[R25C35:R26C44]", "15" );
Set ( "#ReportField[R24C70:R24C83]", "70" );
Set ( "#ReportField[R54C66:R54C78]", "50" );
Set ( "#ReportField[R55C66:R55C78]", "200" );
Set ( "#ReportField[R54C79:R54C91]", "60" );
Set ( "#ReportField[R55C79:R55C91]", "41" );

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
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Divisions
	// *************************
	
	p = Call ( "Catalogs.Divisions.Create.Params" );
	p.Company = Env.Company;
	for i = 1 to 3 do
		p.Description = "Division" + i + ": " + id;;
		p.Cutam = "Cutam: " + i;
		Call ( "Catalogs.Divisions.Create", p );
	enddo;
	
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
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[TaxAdministration]", "TaxAdmin: " + id );
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
