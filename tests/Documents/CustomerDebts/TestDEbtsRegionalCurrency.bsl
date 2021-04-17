// Create test doc
// checking records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28272D30" );
env = getEnv ( id );
createEnv ( env );

//
//	Create test doc
//
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
Click ( "#FormCreateByParameterDebts" );

With ( "Customer Debts (cr*" );
Put ( "#Account", "11000" );
table = Get ( "#Debts" );

Click ( "#DebtsAdd" );

Put ( "#DebtsCustomer", env.Customer, table );
Next ();
Put ( "#DebtsAmount", "1000", table );
try
	Put ( "#DebtsContractAmount", "100", table );
	Stop ("Must be error!");
except
endtry;	

//
//	posting and checking records
//
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Customer Debts*" );
Call ( "Common.CheckLogic", "#TabDoc" );


// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	RegisterEnvironment ( id );

EndProcedure
