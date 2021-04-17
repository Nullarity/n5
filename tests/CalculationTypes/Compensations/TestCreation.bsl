Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Commando ( "e1cib/list/ChartOfCalculationTypes.Compensations" );
list = With ( "Compensations" );

Click ( "#FormCreate" );
With ( "Compensations (cr*" );

checkMethodChanges ();

Set ( "#Description", env.Description );
Next ();
Check ( "#Code", env.ID );

selectTaxes ( env );

Click ( "#FormWriteAndClose" );
With ( list );
Click ( "#FormChange" );
With ( "* (Comp*" );

checkTaxes ( env );

// ***********************************
// Procedures
// ***********************************

Function getEnv ()

	id = Call ( "Common.GetID" );//Call ( "Common.ScenarioID", "2810B600" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Description", id );
	p.Insert ( "Tax1", "T1" + id );
	p.Insert ( "Tax2", "T2" + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Taxes
	// *************************
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Tax1;
	p.Account = "24010";
	Call ( "CalculationTypes.Taxes.Create", p );
	p.Description = Env.Tax2;
	Call ( "CalculationTypes.Taxes.Create", p );

	Call ( "Common.StampData", id );

EndProcedure

Procedure checkMethodChanges ()

	CheckState ( "#Base", "Enable", false );
	CheckState ( "#HourlyRate", "Visible", false );
	
	Pick ( "#Method", "Hourly Rate" );
	CheckState ( "#Base", "Enable", false );
	CheckState ( "#HourlyRate", "Visible", false );
	Check ( "#Description", "Hourly Rate" );
	
	Pick ( "#Method", "Percent" );
	CheckState ( "#Base", "Enable" );

	Click ( "#BaseAdd" );
	Click ( "#BaseAdd" );
	Click ( "#BaseAdd" );

	Pick ( "#Method", "Monthly Rate" );
	CheckState ( "#Base", "Enable", false );
	CheckState ( "#HourlyRate", "Visible" );
	
	Pick ( "#Method", "Percent" );

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
	
EndProcedure

Procedure selectTaxes ( Env )

	table = Activate ( "#Taxes" );
	Click ( "#TaxesMarkAll" );
	Click ( "#TaxesUnmarkAll" );
	
	GotoRow ( table, "Tax", Env.Tax1 );
	Click ( "Use" );
	
	GotoRow ( table, "Tax", Env.Tax2 );
	Click ( "Use" );

EndProcedure

Procedure checkTaxes ( Env )

	table = Activate ( "#Taxes" );
	
	GotoRow ( table, "Tax", Env.Tax1 );
	Check ( "#TaxesUse", "Yes" );
	
	GotoRow ( table, "Tax", Env.Tax2 );
	Check ( "#TaxesUse", "Yes" );

EndProcedure
