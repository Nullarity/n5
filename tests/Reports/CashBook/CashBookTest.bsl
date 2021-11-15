Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE5C24D" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open Cash receipt
// *************************

p = Call ( "Common.Report.Params" );
p.Path = "e1cib/app/Report.CashBook";
p.Title = "Cash Book*";
filters = new Array ();
item = Call ( "Common.Report.Filter" );
item.Name = "Company";
item.Value = env.Company;
filters.Add ( item );
item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = " 1/ 1/2019";
item.ValueTo = "12/31/2019";
filters.Add ( item );
p.Filters = filters;
form = With ( Call ( "Common.Report", p ) );
settings = Activate ( "#UserSettings" );
settings.GotoFirstRow ();
Activate ( "#UserSettingsUse", settings );
Click ( "#UserSettingsUse", settings );
With ( form );
Click ( "#GenerateReport" );
With ( form );
Call ( "Common.CheckLogic", "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Receipt", "Cash Receipt: " + ID );
	p.Insert ( "Expense", "Cash Expense: " + ID );
	p.Insert ( "Company", "_Company: " + ID );
	p.Insert ( "Customer", "_Customer: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	
	Call ( "Catalogs.Companies.Create", Env.Company );
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Organization
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Click ( "#Customer" );
	Click ( "#Vendor" );
	Put ( "#Description", Env.Customer );
	Click ( "#FormWrite" );
	With ( Env.Customer + "*" );
	Click ( "Contracts", GetLinks () );
	With ( Env.Customer + "*" );
	Click ( "#FormCreate" );
	With ( "Contracts (create)" );
	contract = "Contract: " + id;
	Put ( "#Description", contract );
	Put ( "#Company", env.Company );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Roles
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (cr*" );
	Put ( "#Company", env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (cr*" );
	Put ( "#Company", env.Company );
	Put ( "#User", "Accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	// *************************
	// Create Operation receipt
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Operations" );
	With ( "Operations (cr*" );
	Put ( "#Operation", "Cash Receipt" );
	Put ( "#Description", Env.Receipt );
	Click ( "#Simple" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Operation expense
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Operations" );
	With ( "Operations (cr*" );
	Put ( "#Operation", "Cash Expense" );
	Put ( "#Description", Env.Expense );
	Click ( "#Simple" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Customer Payment
	// *************************
	year = Format ( CurrentDate (), "DF='yyyy'" );
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Payment" );
	form = With ( "Customer Payment (*" );
	Put ( "#Date", "01/01/2019" );
	Put ( "#Company", Env.Company );
	Put ( "#Customer", Env.Customer );
	Put ( "#Contract", contract );
	Put ( "#Amount", "5000" );
	Put ( "#Currency", "MDL" );
	Put ( "#Method", "Cash" );
	Click ( "#NewReceipt" );
	
	With ( "Cash Receipt" );
	Put ( "#Number", 100 );
	Click ( "#FormOK" );

	With ( form );
	Put ( "#Account", "2411" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Vendor Payment
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorPayment" );
	form = With ( "Vendor Payment (*" );
	Put ( "#Date", "01/01/2019" );
	Put ( "#Company", Env.Company );
	Put ( "#Vendor", env.Customer );
	Put ( "#Contract", contract );
	Put ( "#Amount", "50" );
	Put ( "#Currency", "MDL" );
	Put ( "#Method", "Cash" );
	Click ( "#NewVoucher" );
	
	With ( "Cash Voucher" );
	Put ( "#Number", 102 );
	Click ( "#FormOK" );

	With ( form );
	Put ( "#Account", "2411" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Entry
	// *************************
	
	// Receipt USD
	
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
	form = With ( "Entry (cr*" );
	Put ( "#Operation", Env.Receipt );
	Put ( "#Date", "01/02/2019" );
	Put ( "#Company", Env.Company );
	Click ( "#RecordsContextMenuAdd" );
	
	With ( "Record" );
	Put ( "#AccountDr", "2412" );
	Put ( "#AccountCr", "2212" );
	Put ( "#DimCr1", Env.Customer );
	Put ( "#CurrencyDr", "USD" );
	Put ( "#CurrencyCr", "USD" );
	Put ( "#RateDr", "18" );
	Put ( "#RateCr", "18" );
	Put ( "#CurrencyAmountDr", "1000" );
	Put ( "#CurrencyAmountCr", "1000" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#NewReceipt" );
	
	With ( "Cash Receipt" );
	Put ( "#Number", 103 );
	Click ( "#FormOK" );

	With ( form );
	Click ( "#FormPostAndClose" );

	
	// Expense USD
	
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
	form = With ( "Entry (cr*" );
	Put ( "#Operation", Env.Expense );
	Put ( "#Date", "01/02/2019" );
	Put ( "#Company", Env.Company );
	Click ( "#RecordsContextMenuAdd" );
	
	With ( "Record" );
	Put ( "#AccountDr", "5212" );
	Put ( "#AccountCr", "2412" );
	Put ( "#DimDr1", Env.Customer );
	Put ( "#CurrencyDr", "USD" );
	Put ( "#CurrencyCr", "USD" );
	Put ( "#RateDr", "18" );
	Put ( "#RateCr", "18" );
	Put ( "#CurrencyAmountDr", "50" );
	Put ( "#CurrencyAmountCr", "50" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#NewVoucher" );
	
	With ( "Cash Voucher" );
	Put ( "#Number", 104 );
	Click ( "#FormOK" );

	With ( form );
	Click ( "#FormPostAndClose" );

	number = 104;
	for i = 1 to 26 do
	
		
		// Receipt MDL
		MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
		form = With ( "Entry (cr*" );
		Put ( "#Operation", Env.Receipt );
		Put ( "#Date", "02/01/2019" );
		Put ( "#Company", Env.Company );
		Click ( "#RecordsContextMenuAdd" );
		
		With ( "Record" );
		Put ( "#AccountDr", "2411" );
		Put ( "#AccountCr", "2211" );
		Put ( "#DimCr1", Env.Customer );
		Put ( "#Amount", Format ( i*10, "NG=" ) );
		Click ( "#FormOK" );
		
		With ( form );
		Click ( "#NewReceipt" );
		
		With ( "Cash Receipt" );
		number = number + 1;
		Put ( "#Number", number );
		Click ( "#FormOK" );

		With ( form );
		Click ( "#FormPostAndClose" );
		
		// Expense USD
	
		MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
		form = With ( "Entry (cr*" );
		Put ( "#Operation", Env.Expense );
		Put ( "#Date", "02/01/2019" );
		Put ( "#Company", Env.Company );
		Click ( "#RecordsContextMenuAdd" );
		
		With ( "Record" );
		Put ( "#AccountDr", "5212" );
		Put ( "#AccountCr", "2412" );
		Put ( "#DimDr1", Env.Customer );
		Put ( "#CurrencyDr", "USD" );
		Put ( "#CurrencyCr", "USD" );
		Put ( "#RateDr", "18" );
		Put ( "#RateCr", "18" );
		amount = Format ( i, "NG=" );
		Put ( "#CurrencyAmountDr", amount );
		Put ( "#CurrencyAmountCr", amount );
		Click ( "#FormOK" );
		
		With ( form );
		Click ( "#NewVoucher" );
		
		With ( "Cash Voucher" );
		number = number + 1;
		Put ( "#Number", number );
		Click ( "#FormOK" );

		With ( form );
		Click ( "#FormPostAndClose" );
		
		// Expense MDL
		MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
		form = With ( "Entry (cr*" );
		Put ( "#Operation", Env.Expense );
		Put ( "#Date", "02/01/2019" );
		Put ( "#Company", Env.Company );
		Click ( "#RecordsContextMenuAdd" );
		
		With ( "Record" );
		Put ( "#AccountDr", "2211" );
		Put ( "#AccountCr", "2411" );
		Put ( "#DimDr1", Env.Customer );
		Put ( "#Amount", i );
		Click ( "#FormOK" );
		
		With ( form );
		Click ( "#NewVoucher" );
		
		With ( "Cash Voucher" );
		number = number + 1;
		Put ( "#Number", number );
		Click ( "#FormOK" );

		With ( form );
		Click ( "#FormPostAndClose" );

	
	enddo;
	
	CloseAll ();

	RegisterEnvironment ( id );

EndProcedure
