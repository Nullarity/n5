Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A61A579" );
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
GotoRow ( "#List", "Description", "Информация о выплатах нерезидентам и подоходном налоге (2014)" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "03/31/2019" );
Put ( "#DateEnd", "03/31/2019" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
Click ( "Yes", DialogsTitle );

With ( list );
Set ( "#ReportField[R27C18:R27C20]", 500 );
Set ( "#ReportField[R27C21:R27C22]", 200 );
Set ( "#ReportField[R45C18:R45C20]", 400 );
Set ( "#ReportField[R45C21:R45C22]", 300 );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
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
	With ();
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Put ( "#RegistrationDate", "01/10/2015" );
	Click ( "#FormWrite" );
	
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
	Set ( "#ReportField[TaxAdministration]", "TaxAdmin: " + id );
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure