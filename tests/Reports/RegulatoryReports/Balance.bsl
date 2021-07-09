Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B5DC38A" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Баланс" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "01/01/2017" );
Put ( "#DateEnd", "03/31/2017" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R181C15:R182C18]", "88" );
Set ( "#ReportField[R186C15:R186C18]", "100" );

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
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
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
	
	addFlow ( "010" );
	addFlow ( "020" );
	addFlow ( "030" );
	addFlow ( "040" );
	addFlow ( "100" );
	addFlow ( "140" );
	addFlow ( "150" );
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Current );
	p.Company = env.Company;
	p.Records.Add ( row ( "0", "6111", "6111" ) );
	p.Records.Add ( row ( "0", "6121", "6121" ) );
	p.Records.Add ( row ( "7111", "0", "7111" ) );
	p.Records.Add ( row ( "7111", "2151", "711102151" ) );
	p.Records.Add ( row ( "7141", "0", "7141" ) );
	p.Records.Add ( row ( "1110", "0", "1110" ) );
	p.Records.Add ( row ( "1231", "0", "1231" ) );
	p.Records.Add ( row ( "2111", "0", "2111" ) );
	p.Records.Add ( row ( "2411", "0", "2411", "010" ) );
	p.Records.Add ( row ( "0", "2412", "2412", , "020" ) );
	p.Records.Add ( row ( "2411", "0", "2411", "030" ) );
	p.Records.Add ( row ( "0", "2412", "2412", , "040" ) );
	p.Records.Add ( row ( "2441", "0", "2411", , , "100" ) );
	p.Records.Add ( row ( "0", "2441", "2412", , , , "140" ) );
	p.Records.Add ( row ( "2441", "0", "2441", , , "150" ) );
	p.Records.Add ( row ( "0", "2441", "2412", , , , "150" ) );
	p.Records.Add ( row ( "3111", "0", "3111" ) );
	p.Records.Add ( row ( "3131", "0", "3131" ) );
	p.Records.Add ( row ( "0", "3331", "3331" ) );
	p.Records.Add ( row ( "0", "3412", "3412" ) );
	p.Records.Add ( row ( "2251", "0", "2251" ) );
	p.Records.Add ( row ( "2171", "5211", "217105211" ) );
	p.Records.Add ( row ( "2172", "4130", "217204130" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = local ( env.Last );
	p.Company = env.Company;
	p.Records.Add ( row ( "0", "6121", "61210" ) );
	p.Records.Add ( row ( "7111", "2111", "71110" ) );
	p.Records.Add ( row ( "7111", "2151", "7111021510" ) );
	p.Records.Add ( row ( "7141", "0", "71410" ) );
	p.Records.Add ( row ( "1231", "0", "12310" ) );
	p.Records.Add ( row ( "2111", "2411", "21110" ) );
	p.Records.Add ( row ( "2411", "0", "24110", "010" ) );
	p.Records.Add ( row ( "0", "2412", "24120", , "020" ) );
	p.Records.Add ( row ( "3111", "61216", "31110" ) );
	p.Records.Add ( row ( "3131", "0", "3131" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause (2);
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
	Set ( "#ReportField[KindOfActivity]", "KindOfActivity: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[CFP]", "CFP: " + id );
	Set ( "#ReportField[CFOJ]", "CFOJ: " + id );
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
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

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined, DimCr1 = undefined, DimDr2 = undefined, DimCr2 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	row.DimCr1 = DimCr1;
	row.DimDr2 = DimDr2;
	row.DimCr2 = DimCr2;
	return row;
	
EndFunction

Procedure addFlow ( Code )
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.CashFlows" );
	form = With ( "Cash Flows (create)" );
	Put ( "#Description", Code );
	Put ( "#FlowType", "Type_" + Code );
	Put ( "#Code", Code );
	Click ( "Yes", Forms.Get1C () ); 
	Click ( "#FormWrite" );
	
	try
		Close ( form );
	except
		Click ( "OK", Forms.Get1C () ); 
		Close ( form );
		Click ( "No", Forms.Get1C () ); 
	endtry;	
	
EndProcedure

