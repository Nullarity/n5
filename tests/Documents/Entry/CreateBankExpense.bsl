// Create a new Entry
// Check if Reference field is invisible
// Select Operation with Bank Expense type, simple variant
// Check if Reference field is visible

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "272B2026" );
env = getEnv ( id );
createEnv ( env );

// Create a new Entry
Commando ( "e1cib/data/Document.Entry" );
form = With ( "Entry (cr*" );

// Check Reference field
CheckState ( "#Reference, #ReferenceDate", "Visible", false );

// Set Operation
Put ( "#Operation", env.Operation );

// Check Reference field
CheckState ( "#Reference, #ReferenceDate", "Visible" );

// Set some values
Set ( "#Reference", "some ref" );

// Clean Operation and check Reference
Clear ( "#Operation" );
Click ( "Yes", "1?:*" );
CheckState ( "#Reference, #ReferenceDate", "Visible", false );

// Set Operation
Put ( "#Operation", env.Operation );
CheckState ( "#Reference, #ReferenceDate", "Visible" );
Check ( "#Reference", "" ); // This field should be clean here


// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Operation", "Operation " + ID );
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
	p.Operation = "Bank Expense";
	p.Description = Env.Operation;
	p.Simple = true;
	p.AccountCr = "10300";
	Call ( "Catalogs.Operations.Create", p );
	
	RegisterEnvironment ( id );

EndProcedure
