Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A6B5118" );
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
GotoRow ( "#List", "Description", "Сбор за услуги мобильной связи" );
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
Set ( "#ReportField[R29C17:R30C22]", "2" );

// *************************
// Current Report
// *************************

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Сбор за услуги мобильной связи" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

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
Set ( "#ReportField[R29C1:R30C16]", "100" );

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
	Click ( "#FormWriteAndClose" );
	
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
	
	Call ( "Common.StampData", id );
	
EndProcedure