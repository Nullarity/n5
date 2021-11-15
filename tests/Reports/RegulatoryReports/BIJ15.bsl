Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6ABCE8" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Current Report
// *************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Недвижимое имущество (годовой)" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "03/31/2019" );
Put ( "#DateEnd", "03/31/2019" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R30C18:R30C20]", "100" );
Set ( "#ReportField[R33C18:R33C20]", "100" );
Set ( "#ReportField[R30C21:R30C22]", "5" );
Set ( "#ReportField[R33C21:R33C22]", "2" );
Set ( "#ReportField[R30C26:R30C29]", "100" );
Set ( "#ReportField[R40C26:R40C29]", "50" );
Set ( "#ReportField[R95C22:R95C24]", "100" );
Set ( "#ReportField[R96C22:R96C24]", "50" );
Set ( "#ReportField[R118C20:R118C23]", "100" );
Set ( "#ReportField[R120C20:R120C23]", "50" );
Set ( "#ReportField[R144C18:R144C19]", "100" );
Set ( "#ReportField[R148C18:R148C19]", "50" );
Set ( "#ReportField[R144C60:R144C61]", "100" );
Set ( "#ReportField[R147C60:R147C61]", "50" );
Set ( "#ReportField[R169C28:R169C31]", "50" );
Set ( "#ReportField[R170C28:R170C31]", "60" );
Set ( "#ReportField[R169C32:R169C35]", "100" );
Set ( "#ReportField[R203C18:R203C20]", "50" );
Set ( "#ReportField[R204C18:R204C20]", "60" );
Set ( "#ReportField[R203C21:R203C23]", "100" );

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
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[TaxAdministration]", "TaxAdmin: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure