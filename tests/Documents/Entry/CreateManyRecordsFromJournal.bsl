// Scenario:
// - Open list of entries
// - Set filter by operation (operation with Simple flag = false)
// - Create a new Entry
// - Create a new posting and check prefilled accounts and flags
// - Create second posting
// - Post document
// - Enable Simple mode and confirm changes
// - Check accounts and flags
// - Post document again

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A08P" );
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

// Create first posting
Click ( "#RecordsAdd" );
With ( "Record" );
checkFields ();
Set ( "#Amount", 100 );
Click ( "#FormOK" );

// Create second posting
With ( form );
Click ( "#RecordsAdd" );
With ( "Record" );
Click ( "#FormOK" );

// Post document
With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
Close ( "Records: *" );

// Enable Simple mode and confirm changes
Click ( "#Simple" );
Click ( "Yes", DialogsTitle );
Activate ( "#OneRecordPage" );
checkFields ();

// Post simple variant
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
Close ( "Records: *" );

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
	p.Simple = false;
	p.AccountDr = Env.AccountDr;
	p.AccountCr = Env.AccountCr;
	Call ( "Catalogs.Operations.Create", p );
	
	RegisterEnvironment ( id );

EndProcedure

Procedure checkFields ()
	
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
	
EndProcedure