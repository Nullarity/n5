// Scenario:
// - Open list of entries
// - Set filter by operation (operation with Simple flag = true)
// - Create a new Entry and check prefilled accounts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25C3A35C" );
env = getEnv ( id );
createEnv ( env );

// Open list
Commando ( "e1cib/list/Document.Entry" );
With ( "Accounting Entries" );

// Set filter by Operation
Put ( "#OperationFilter", env.Operation );

// Create a new Entry
Click ( "#FormCreate" );
form = With ( "Entry (cr*" );

// Check Operation
Check ( "#Operation", Env.Operation );

// Accounts should be readonly
CheckState ( "#AccountDr", "ReadOnly" );
CheckState ( "#AccountCr", "ReadOnly" );

// Check debit dimensions
Choose ( "#DimDr1" );
Close ( "Items" );

// Quantity debit should be enabled
Set ( "#QuantityDr", 1 );

// Credit dimension should be disabled
CheckState ( "#DimCr1", "Enable", false );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Operation", "Operation " + ID );
	p.Insert ( "AccountDr", "2171" );
	p.Insert ( "AccountCr", "0" );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Operation
	// *************************

	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Description = Env.Operation;
	p.Simple = true;
	p.AccountDr = Env.AccountDr;
	p.AccountCr = Env.AccountCr;
	Call ( "Catalogs.Operations.Create", p );
	
	RegisterEnvironment ( id );

EndProcedure
