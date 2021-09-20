// 1. create payment order
// 2. open Bank client, uploading and press fill, test created payment order

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "A0CB");
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

GotoRow("#UserSettings", "Setting", "Receiver");

form = CurrentSource;
Set("#UserSettingsValue", env.Vendor, settings);

CurrentSource = form;

Click("#FormFill");
With();

testUpload("EuroCreditBank", "");
testUpload("Comertbank");
testUpload("Victoriabank");
testUpload("Energbank");
testUpload("ProCreditBank");
testUpload("Eximbank");
testUpload("Mobias", ".DBF");
testUpload("MAIB", ".DBF");
if ( Framework.IsWindows () ) then
	testUpload("FinComPay", ".XML");
endif;

// *************************
// Procedures
// *************************

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Vendor", "Vendor " + ID);
	p.Insert("Account", "Account " + ID);
	p.Insert("Division", "Division " + ID);
	this.Insert("Dir", __.Files + "c5\Unload\");
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
	Put("#CodeFiscal", "55888");
	Click("#Vendor");
	Click("#FormWrite");
	CheckErrors();
	
	Click("Bank Accounts", GetLinks());
	With(Env.Vendor + " (Organizations)");
	Click("#FormCreate");
	
	With("Bank Accounts (create)");
	Put("#Bank", "VICBMD2X");
	Put("#AccountNumber", "555222");
	Put("#Account", "2421");
	Put("#Description", Env.Account);
	Click("#FormWriteAndClose");
	CheckErrors();
	
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
	Put("#CodeFiscal", "55888");
	Click("#FormWrite");
	CheckErrors();
	
	Click("Bank Accounts", GetLinks());
	With("ABC Distributions (Companies)");
	Click("#FormCreate");
	
	With("Bank Accounts (create)");
	Put("#Bank", "VICBMD2X");
	Put("#AccountNumber", "555222");
	Put("#Account", "2421");
	Put("#Description", Env.Account + " 5");
	Click("#FormWriteAndClose");
	CheckErrors();
	
	With("ABC Distributions (Companies)");
	Click("#FormCreate");
	
	With("Bank Accounts (create)");
	Put("#Bank", "VICBMD2X");
	Put("#AccountNumber", "222222");
	Put("#Account", "2421");
	Put("#Description", Env.Account + " 2");
	Click("#FormWriteAndClose");
	CheckErrors();
	With ();
	Close ();
	
	// *************************
	// Create Division
	// *************************
	
	Commando("e1cib/data/Catalog.Divisions");
	With("Divisions (create)");
	Put("#Code", Mid(Call("Common.GetID"), 4, 4));
	Put("#Description", Env.Division);
	Put("#Cutam", "Cutam " + id);
	Put("#Type", "Type " + id);
	Click("#FormWriteAndClose");
	CheckErrors();
	
	// *************************
	// Create Payment order
	// *************************
	
	Commando("e1cib/data/Document.PaymentOrder");
	With("Payment Order (create)");
	Put("#Recipient", Env.Vendor);
	Put("#RecipientBankAccount", Env.Account);
	Put("#Amount", "1000");
	Put("#TerritorialDepartment", Env.Division);
	Put("#VATRate", "20%");
	Put("#IncomeTaxRate", "5");
	Put("#PaymentContent", "PaymentContent " + id);
	Click("#FormWriteAndClose");
	CheckErrors();
	
	RegisterEnvironment(id);
	
EndProcedure

Procedure testUpload(Application, Extension = ".txt")
	
	Put("#BankingApp", Application);
	dir = this.Dir;
	path = dir + Application + Extension;
	Put("#Path", path);
	
	Click("#FormUnload");
	
	Pause(__.Performance * 4);
	
	With();
	Click("#DeleteFile");
	Click("#FormOK");
	With();
	
	searching = path + ?(Application = "EuroCreditBank", ".107", "");
	file = new File(searching);
	Assert(file.Exist(), searching).IsTrue();
	DeleteFiles(path);
	
EndProcedure

