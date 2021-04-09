// Create test doc
// checking records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28524767" );
env = getEnv ( id );
createEnv ( env );

//
//	Create test doc
//
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
Click ( "#FormCreateByParameterVendorDebts" );

With ( "Vendor Debts (cr*" );
Put ( "#Account", "20000" );
Put ( "#Currency", "CAD" );
table = Get ( "#Debts" );

Click ( "#DebtsAdd" );

Put ( "#DebtsVendor", env.Vendor, table );
Next ();
Put ( "#DebtsAmount", "1000", table );
Put ( "#DebtsContractAmount", "100", table );

//
//	posting and checking records
//
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Vendor Debts*" );
Call ( "Common.CheckLogic", "#TabDoc" );


// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	form = With ( "Organizations (create)" );
	Put ( "#Description", Env.Vendor );
	Click ( "#Vendor" );
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
