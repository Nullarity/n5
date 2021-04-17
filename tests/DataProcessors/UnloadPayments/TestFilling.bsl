// 1. create payment order
// 2. open Bank client, uploading and press fill, test created payment order

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "2BD6759B");
env = getEnv(id);
createEnv(env);

// *************************
// Create Bank Client, Uploading
// *************************

Commando("e1cib/app/DataProcessor.UnloadPayments");
With();
Click("#Fill");
With("Fill Payment Orders: Setup Filters");

settings = Get("#UserSettings");
GotoRow("#UserSettings", "Setting", "Period");
Click("#UserSettingsUse");

GotoRow("#UserSettings", "Setting", "Recipient");
form = CurrentSource;
Choose("#UserSettingsValue", settings);

//With("Select data type");
//GotoRow("#TypeTree", "", "Organizations");
//Click("#OK");
With("Organizations");
GotoRow("#List", "Name", env.Vendor);
Click("#FormChoose");
CurrentSource = form;

Click("#FormFill");

With();
table = Activate("#PaymentOrders");
if (Call("Table.Count", table) <> 1) then
	Stop("Must be only one row");
endif;

Check("#PaymentOrdersPaymentOrderRecipient", env.Vendor, table);



// *************************
// Procedures
// *************************

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Vendor", "Vendor " + ID);
	p.Insert("Account", "Account " + ID);
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Customer, bank account
	// *************************
	
	Commando("e1cib/data/Catalog.Organizations");
	With("Organizations (create)");
	Put("#Description", Env.Vendor);
	Click("#Vendor");
	Click("#FormWrite");
	
	Click("Bank Accounts", GetLinks());
	With(Env.Vendor + " (Organizations)");
	Click("#FormCreate");
	
	With("Bank Accounts (create)");
	Put("#Bank", "Bank");
	Put("#AccountNumber", "555222");
	Put("#Account", "2421");
	Put("#Description", Env.Account);
	Click("#FormWriteAndClose");
	
	// *************************
	// Create Payment order
	// *************************
	
	Commando("e1cib/data/Document.PaymentOrder");
	With("Payment Order (create)");
	Put("#Recipient", Env.Vendor);
	Put("#RecipientBankAccount", Env.Account);
	Put("#Amount", "1000");
	Click("#FormWriteAndClose");
	
	RegisterEnvironment(id);
	
EndProcedure

