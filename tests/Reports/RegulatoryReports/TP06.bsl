﻿Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A16Y" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Last Report
// *************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
Pause ( __.Performance * 3 );
With();
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Рыночный сбор" );
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
Set ( "#ReportField[R37C11:R37C15]", "5" );

// *************************
// Current Report
// *************************

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Рыночный сбор" );
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
Set ( "#ReportField[R37C1:R37C10]", "10" );
Set ( "#ReportField[R37C21:R37C24]", "15" );
Set ( "#ReportField[R72C28:R72C33]", "75" );
Set ( "#ReportField[R73C28:R73C33]", "20" );

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
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
	Pause ( __.Performance * 3 );
	With();
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