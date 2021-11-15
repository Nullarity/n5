// 1. Create Entry with different currency rate
// 2. Change currency rate
// 3. Create CalculationRatesDifferences and test movements + and -

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2815F34A" );
env = getEnv ( id );
createEnv ( env );


// *************************
// Create CalculationRatesDifferences test positive differences
// *************************

Commando ( "e1cib/list/Document.CalculationRatesDifferences" );
With ();
p = Call ( "Common.Find.Params" );
p.What = id + " Positive";
p.Where = "Memo";
Call ( "Common.Find", p );
try
	Click ( "#FormChange" );
	With ( "Calculation of Rates Differences #*" );
	Click ( "#FormUndoPosting" );
except
	Click ( "#FormCreate" );
	With ();
endtry;

Put ( "#Date", "02/02/2018" );
Put ( "#Memo", id + " Positive" );
Put ( "#Company", env.Company );
Put ( "#AccountPositive", "70100" );
Put ( "#AccountNegative", "8111" );
Put ( "#Dim1", env.Expenses );
Put ( "#Dim2", "Administration" );
Put ( "#CashFlow", env.CashFlow );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
CheckTemplate ( "#TabDoc", "Records: *" );

Run ( "TestNegative", env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company " + ID );
	p.Insert ( "CashFlow", "CashFlow " + ID );
	p.Insert ( "Expenses", "Expenses " + ID );
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

	// *************************
	// Create CashFlow
	// *************************

	Call ( "Catalogs.CashFlow.Create", Env.CashFlow );

	// *************************
	// Create Expenses
	// *************************

	Call ( "Catalogs.Expenses.Create", Env.Expenses );

	// *************************
	// Create Entry
	// *************************

	Commando ( "e1cib/data/Document.Entry" );
	form = With ();
	Put ( "#Date", "01/01/2018" );
	Put ( "#Memo", id );
	Put ( "#Company", Env.Company );
	Click ( "#RecordsAdd" );
	With ();
	Put ( "#AccountDr", "11000" );
	Put ( "#CurrencyDr", "CAD" );
	Put ( "#RateDr", "1.2" );
	Put ( "#CurrencyAmountDr", "1000" );
	Put ( "#AccountCr", "Special" );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );

	// *************************
	// Change currency rate (+)
	// *************************

	Commando ( "e1cib/list/InformationRegister.ExchangeRates" );
	With ();
	
	Click ( "#FormCreate" );
	With ();
	Put ( "#Period", "02/01/2018" );
	Put ( "#Currency", "CAD" );
	Put ( "#Rate", "1.5" );
	Click ( "#FormWriteAndClose" );
	try
		Click ( "OK", "1?:*" );
		Click ( "#FormClose" );
		Click ( "No", "1?:*" );
	except
	endtry;

	// *************************
	// Change currency rate (-)
	// *************************

	Commando ( "e1cib/list/InformationRegister.ExchangeRates" );
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Period", "03/01/2018" );
	Put ( "#Currency", "CAD" );
	Put ( "#Rate", "1.3" );
	Click ( "#FormWriteAndClose" );
	try
		Click ( "OK", "1?:*" );
		Click ( "#FormClose" );
		Click ( "No", "1?:*" );
	except
	endtry;

	RegisterEnvironment ( id );

EndProcedure
