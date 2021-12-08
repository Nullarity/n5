// Scenario:
// - Create a new Entry, operation = Cash Expense
// - Change the entry to operation = Cash Receipt
// - Check if Voucher marked for deletion and Cash Receipt comes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0FQ" );
env = getEnv ( ID );
createEnv ( env );

expenseID = id + " expense";
receiptID = id + " receipt";

// ************
// Create Entry
// ************

Commando ( "e1cib/data/Document.Entry" );
With ( "Entry (cr*" );
Put ( "#Operation", Env.OperationExpense );
Put ( "#Content", expenseID );
Click ( "#FormPost" );
Put ( "#Operation", Env.OperationReceipt );
Click("#Button0", "1?:*"); // Yes
Put ( "#Content", receiptID );
Click ( "#FormPost" );

// ************
// Open Journal
// ************

#region checkIfExpenseRemoved
Call ("Journals.Cash.ListByMemo", receiptID);
With ();
Assert (Call("Table.Count", Get("#List"))).Equal (2);
Click ( "#FormSetDeletionMark" );
Get ( "Do you want to remove the dele*", "1?:*" );
Click ( "No", "1?:*" );
#endregion

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "OperationExpense", "Expense " + ID );
	p.Insert ( "OperationReceipt", "Receipt " + ID );
	p.Insert ( "Individual", "Individual " + ID );
	p.Insert ( "Location", "Location " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Operation: Expense
	// *************************

	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Operation = "Cash Expense";
	p.Description = Env.OperationExpense;
	p.Simple = true;
	p.AccountDr = "2262";
	p.AccountCr = "2411";
	Call ( "Catalogs.Operations.Create", p );
	p.Operation = "Cash Receipt";
	p.Description = Env.OperationReceipt;
	p.Simple = true;
	p.AccountCr = "2262";
	p.AccountDr = "2411";
	Call ( "Catalogs.Operations.Create", p );

	RegisterEnvironment ( id );

EndProcedure
