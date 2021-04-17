// *** for each bank
//1. Test reading file
//2. test downloading data
//3. check documents movements

// in file code fiscal 26990BF1
//vendor/customer = 26988999888
//customer = 16988999888

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "2BDC8BAF");
env = getEnv(id);
createEnv(env);

// *************************
// Comert
// *************************

form = createBankClient(env);
readFile("Comert", "comert.xml");
checkDownload(form, "TestComert", "TestInternal");

return;

// *************************
// VictoriaBank
// *************************

form = createBankClient(env);
readFile("VictoriaBank, MoldincomBank", "victoriabank.txt");
checkDownload(form, "TestVictoria", "TestInternal");

// *************************
// Mobias
// *************************

form = createBankClient(env);
readFile("Mobias Banca", "mobias.dbf");
checkDownload(form, "TestMobias", "TestPayment");

// *************************
// Eximbank
// *************************

form = createBankClient(env);
readFile("Eximbank", "exim.dbf");
checkDownload(form, "TestEximbank");

// *************************
// FinComPay
// *************************

form = createBankClient(env);
readFile("FinComPay", "fincompay.xml", true);
checkDownload(form, "TestFinComPay", "TestVendorPayment");

// *************************
// EuroCreditBank
// *************************

form = createBankClient(env);
readFile("EuroCreditBank", "ecb.txt");
checkDownload(form, "TestEuroCreditBank");

// *************************
// MAIB
// *************************

form = createBankClient(env);
readFile("MAIB", "maib.dbf");
checkDownload(form, "TestMAIB");

// *************************
// Procedures
// *************************

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
	Click("#Customer");
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
	Put("#PayrollPeriod", "Other");
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

Function createBankClient(Env)
	
	Commando("e1cib/data/Document.LoadPayments");
	form = With();
	Put("#BankAccount", Env.Account);
	Click ( "Default Values" );
	Put("#InternalMovement", Env.Internal);
	Put("#OtherExpense", Env.OtherExpense);
	Put("#OtherReceipt", Env.OtherReceipt);
	return form;
	
EndFunction

Procedure readFile(Bank, File, ShouldBeErrors = false)

	Put("#Application", Bank);
	path = __.Files + "loadpayments\";
	Set("#Path", path + File);
	Next();
	With();
	Click("Yes");
	With();
	Pause (4);
	
	if ( ShouldBeErrors ) then
		Assert ( FindMessages("*").Count(), "There are two errors" ).Equal(2);
	else
		CheckErrors();
	endif;
	
EndProcedure

Procedure checkDownload(Form, TestDetails, TestDocument = undefined)
	 
    Pause (1);
	With(Form);
	Click("#MarkAllReceipts");
	Click("#MarkAllExpenses");
	Click("#FormPost");
	Pause(4);
	CheckErrors ();
	
	// Uncomment it after implementing project 000001966
//	Run(TestDetails);
	
	With(Form);
	if (TestDocument = undefined) then
		Close(Form);
		return;
	endif;
	details = Get("#Details");
	if ( TestDetails = "TestFinComPay" ) then
		GotoRow(details, "Amount", "72,000.00");
	else
		GotoRow(details, "Amount", "64.30");
	endif;
	details.Choose();
//	Run(TestDocument);
	Close(Form);
	
EndProcedure

