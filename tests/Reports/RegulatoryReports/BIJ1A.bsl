
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6EC64E" );
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
GotoRow ( "#List", "Description", "Приложение к отчету о недвижимом имуществе" );
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
	Put ( "#RegistrationDate", "01/10/2018" );
	Click ( "#FormWrite" );
	
	// *************************
	// Create Address
	// *************************
	
	With ( env.Company + "*" );
	Click ( "Addresses", GetLinks () );
	With ( env.Company + "*" );
	Click ( "#FormCreate" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	address = "Address: " + id;
	Put ( "#Address", address );
	Click ( "#FormWriteAndClose" );
	
	With ( env.Company + "*" );
	Click ( "Main", GetLinks () );
	With ( env.Company + "*" );
	Put ( "#PaymentAddress", address );
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
	Set ( "#ReportField[TaxAdministration]", "TaxAdmin: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure