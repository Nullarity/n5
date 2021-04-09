Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6D5004" );
env = getEnv ( id );
createEnv ( env );

// Last Report

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

// Create Report
With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "1-IM" );
Click ( "#FormChoose" );

With ( list );
Pause ( 1 );
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "12/31/2016" );
Put ( "#DateEnd", "12/31/2016" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R14C9:R14C26]", "Province: " + env.ID );
Set ( "#ReportField[R17C7:R17C20]", "Street: " + env.ID );
Set ( "#ReportField[R17C23:R17C26]", "Apartment: " + env.ID );
Set ( "#ReportField[R27C9:R27C20]", "Owner type: " + env.ID );

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "1-IM" );
Click ( "#FormChoose" );

With ( list );
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
	
	// Create Report
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	
	// Select period
	form = With ( "Значения по умолчанию" );
	Pause (1);
	Set ( "#ReportField[CUIO]", "CUIO: " + id );
	Set ( "#ReportField[CFP]", "CFP: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[Region]", "Region: " + id );
	Set ( "#ReportField[KindOfActivity]", "KindOfActivity: " + id );
	Close ( form );
	
	Call ( "Common.StampData", id );
	
EndProcedure

Function local ( Date1, Date2 = undefined, Date3 = undefined )
	
	if ( Date2 = undefined ) then
		date = Date1;
	else
		date = Date ( Date1, Date2, Date3 );
	endif;
	return Format ( date, "DLF = 'DT'" );
	
EndFunction