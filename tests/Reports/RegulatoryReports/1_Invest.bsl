Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AC228" );
env = getEnv ( id );
createEnv ( env );

// Last Report

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "1-Invest" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "12/31/2016" );
Put ( "#DateEnd", "12/31/2016" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes" );

With ( list );
Set ( "#ReportField[R13C5:R13C16]", "Province: " + id );
Set ( "#ReportField[R16C3:R16C12]", "Street: " + id );
Set ( "#ReportField[R16C14:R16C16]", "Apartment: " + id );
Set ( "#ReportField[R25C7:R25C13]", "Owner type: " + id );

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "1-Invest" );
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
Set ( "#ReportField[R153C36:R153C45]", "5000" );
Set ( "#ReportField[R132C36:R132C45]", "300" );

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
	
	core = "Core";
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
	Set ( "#ReportField[CFP]", "CFP: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[Region]", "Region: " + id );
	Set ( "#ReportField[KindOfActivity]", "KindOfActivity: " + id );
	Close ( form );
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Current );
	p.Company = env.Company;
	records = p.Records;
	records.Add ( row ( "0", "3111", "3111" ) );
	records.Add ( row ( "0", "3121", "3121" ) );
	records.Add ( row ( "3131", "0", "3131" ) );
	records.Add ( row ( "3151", "0", "3151" ) );
	records.Add ( row ( "0", "3141", "3141" ) );
	records.Add ( row ( "0", "3210", "3210" ) );
	records.Add ( row ( "0", "3411", "3411" ) );
	records.Add ( row ( "0", "4260", "4260" ) );
	records.Add ( row ( "0", "2220", "2220" ) );
	records.Add ( row ( "0", "6111", "6111" ) );
	records.Add ( row ( "7111", "0", "7111" ) );
	records.Add ( row ( "0", "6211", "6211" ) );
	records.Add ( row ( "7211", "0", "7211" ) );
	records.Add ( row ( "7311", "0", "7311" ) );
	Call ( "Documents.Entry.Create", p );
	
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

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined, DimCr1 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	row.DimCr1 = DimCr1;
	return row;
	
EndFunction






