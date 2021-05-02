Call ( "Common.Init" );
CloseAll ();

env = getEnv ();

Commando ( "e1cib/list/ChartOfCalculationTypes.Taxes" );
list = With ( "Taxes" );

Click ( "#FormCreate" );
With ( "Taxes (cr*" );

Put ( "#Description", env.Description );
Put ( "#Account", "5333" );

CheckState ( "#Base", "Enable" );

Click ( "#BaseAdd" );
Click ( "#BaseAdd" );
Click ( "#BaseAdd" );

Pick ( "#Method", "Fixed Amount" );
CheckState ( "#Base", "Enable", false );

Pick ( "#Method", "Percent" );
Put ( "#Description", env.Description );

table = Activate ( "#Base" );
table.GotoFirstRow ();
try
	table.GotoNextRow ();
	error = true;
except
	error = false;
endtry;

if ( error ) then
	Stop ( "List of compensations should be empty!" );
endif;

Click ( "#FormWriteAndClose" );
With ( list );

Click ( "#FormChange" );

// ***********************************
// Procedures
// ***********************************

Function getEnv ()

	id = Call ( "Common.GetID" );//Call ( "Common.ScenarioID", "2810B8BC#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Description", id );
	return p;

EndFunction
