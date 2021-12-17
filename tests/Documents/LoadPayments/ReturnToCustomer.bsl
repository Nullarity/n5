// Reading the file and check refund
// vendor/customer = 26988999888
// customer = 16988999888

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "A0GN");
env = getEnv(id);
createEnv(env);

#region newLoadPayments
Commando("e1cib/data/Document.LoadPayments");
form = With();
Put("#BankAccount", env.Account);
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

#region checking
Pause(4);
Assert ( Fetch ( "#Receipts / Document [ 1 ]" ) ).Contains ("Refund from Vendor");
Assert ( Fetch ( "#Expenses / Document [ 1 ]" ) ).Contains ("Refund to Customer");
#endregion

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Customer", "Customer " + ID);
	p.Insert("Vendor", "Vendor " + ID);
	p.Insert("Account", "BC ""Victoriabank"" S.A. Chisinau, MD74VI000000222462047MDL");
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
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

	RegisterEnvironment(id);
	
EndProcedure
