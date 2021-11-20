// Scenario:
// - Create a new Entry (cash receipt)
// - Copy the cash receipt and check if data is copying too

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0FO" );
env = getEnv ( ID );
createEnv ( env );

#region cashReceipt
Commando ( "e1cib/data/Document.Entry" );
With ( "Entry (cr*" );
Put ( "#Operation", Env.OperationReceipt );
Put ( "#Content", id );
//Put ( "#Memo", id );
Click ( "#FormPost" );
#endregion

#region checkCopying
Call ("Journals.PettyCash.ListByMemo", id);
With ();
Click("#FormCopy");
With();
Click("#NewReceipt");
With ();
Check ("#Reason", id);
#endregion

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "OperationReceipt", "Operation Receipt" + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newOperation
	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Operation = "Cash Receipt";
	p.Description = Env.OperationReceipt;
	p.Simple = true;
	p.AccountDr = "0";
	p.AccountCr = "0";
	Call ( "Catalogs.Operations.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
