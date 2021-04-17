// Create test doc
// checking records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2863B035" );
env = getEnv ( id );
createEnv ( env );

//
//	Create test doc
//
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
Click ( "#FormCreateByParameterDebts" );

With ( "Customer Debts (cr*" );
Put ( "#Account", "20000" );
Put ( "#Currency", "CAD" );

table = Get ( "#Debts" );


Click ( "#DebtsAdd" );

Put ( "#DebtsCustomer", env.Customer, table );
Next ();
Put ( "#DebtsAdvance", "1000", table );
Put ( "#DebtsContractAdvance", "100", table );

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
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	form = With ( "Organizations (create)" );
	Put ( "#Description", Env.Customer );
	Click ( "#Customer" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );
	With ( "Contracts" );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Put ( "#Currency", "CAD" );
	Put ( "#Description", "General " + id );
	
	Click ( "#FormWriteAndClose" );

	RegisterEnvironment ( id );

EndProcedure
