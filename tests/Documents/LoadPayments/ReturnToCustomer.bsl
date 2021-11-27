// Reading the file and check refund
// vendor/customer = 26988999888
// customer = 16988999888

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "A0G3");
env = getEnv(id);
createEnv(env);

#region newLoadPayments
Commando("e1cib/data/Document.LoadPayments");
form = With();
Put("#BankAccount", env.Account);
Click ( "Default Values" );
Put("#InternalMovement", env.Internal);
Put("#OtherExpense", env.OtherExpense);
Put("#OtherReceipt", env.OtherReceipt);
Put("#Application", "Comert");
path = __.Files + "loadpayments\comert_check_refund.xml";
Set("#Path", path);
Next();
With();
Click("Yes");
Pause (4);
CheckErrors();
With();
#endregion

#region posting
Click("#MarkAllReceipts");
Click("#MarkAllExpenses");
Click("#FormPost");
#endregion

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Customer", "Customer " + ID);
	p.Insert("Vendor", "Vendor " + ID);
	p.Insert("Internal", "Internal " + ID);
	p.Insert("OtherExpense", "Other Expense " + ID);
	p.Insert("OtherReceipt", "Other Receipt " + ID);
	p.Insert("Account", "Account " + ID);
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// ***************************
	// Create Vendor, bank account
	// ***************************
	
	Commando("e1cib/data/Catalog.Organizations");
	With("Organizations (create)");
	Put("#Description", Env.Vendor);
	Put("#CodeFiscal", "26988999888");
	Click("#Vendor");
	Click("#FormWriteAndClose");
	CheckErrors();
	
	Commando("e1cib/data/Catalog.Organizations");
	With("Organizations (create)");
	Put("#Description", Env.Customer);
	Put("#CodeFiscal", "16988999888");
	Click("#Customer");
	Click("#FormWriteAndClose");
	CheckErrors();
	
	// *************************
	// Operations
	// *************************

	createOperation("Bank Expense", Env.Internal, "2421", "2421");
	createOperation("Bank Expense", Env.OtherExpense, "7141", "2421");
	createOperation("Bank Receipt", Env.OtherReceipt, "2421", "6111");

	// *************************
	// change company fiscal code
	// *************************

	Commando("e1cib/list/Catalog.Companies");
	With("Companies");
	p = Call("Common.Find.Params");
	p.Where = "Description";
	p.What = "ABC Distributions";
	Call("Common.Find", p);
	Click("#ListContextMenuChange");
	With("ABC Distributions (Companies)");
	Put("#CodeFiscal", "10013003155");
	Put("#PayrollPeriod", "Month");
	Click("#FormWrite");
	CheckErrors();
	
	Click("Bank Accounts", GetLinks());
	With("ABC Distributions (Companies)");
	Click("#FormCreate");
	
	With("Bank Accounts (create)");
	Put("#Bank", "VICBMD2X");
	Put("#AccountNumber", "555222");
	Put("#Account", "2421");
	Put("#Description", Env.Account);
	Click("#FormWriteAndClose");
	CheckErrors();
	
	RegisterEnvironment(id);
	
EndProcedure

Procedure createOperation(Operation, Description, AccountDr = undefined, AccountCr = undefined)
	
	Commando("e1cib/data/Catalog.Operations");
	With("Operations (create)");
	Put("#Operation", Operation);
	Put("#Description", Description);
	Click("#Simple");
	Put("#AccountDr", AccountDr);
	Put("#AccountCr", AccountCr);
	Click("#FormWriteAndClose");
	
EndProcedure
