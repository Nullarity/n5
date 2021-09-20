Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A6B5125" );
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
GotoRow ( "#List", "Description", "Перевозка пассажиров" );
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
Set ( "#ReportField[R37C11:R38C15]", "10" );
Set ( "#ReportField[R37C16:R38C18]", "5" );
Set ( "#ReportField[R41C11:R42C15]", "6" );
Set ( "#ReportField[R41C16:R42C18]", "6" );

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Перевозка пассажиров" );
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
Set ( "#ReportField[R37C23:R38C25]", "10" );
Set ( "#ReportField[R41C23:R42C25]", "6" );
Set ( "#ReportField[R37C26:R38C29]", "4" );
Set ( "#ReportField[R85C28:R85C33]", "250" );
Set ( "#ReportField[R87C28:R87C33]", "800" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + id );
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
	
	form = With ();
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[TaxAdministration]", "TaxAdmin: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure