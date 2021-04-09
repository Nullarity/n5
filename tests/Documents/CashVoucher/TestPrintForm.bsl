Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2815F4CB" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open Cash voucher
// *************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.CashVoucher" );
With ( "Petty Cash Voucher" );
p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = id;
Call ( "Common.Find", p );
Click ( "#FormDocumentJournalPettyCashPrint" );
form = With ( "Voucher: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );

Run ( "TestEntry", Env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor: " + ID );
	p.Insert ( "OperationExpense", "Cash Expense: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Click ( "#Vendor" );
	Put ( "#Description", Env.Vendor );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Vendor Payment
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorPayment" );
	form = With ( "Vendor Payment (*" );
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Amount", "1000" );
	Put ( "#Currency", "MDL" );
	Put ( "#Method", "Cash" );
	Put ( "#Account", "10400" );
	Click ( "#NewVoucher" );
	
	With ( "Cash Voucher" );
	Put ( "#Reason", "Reason: " + id );
	Put ( "#ID", "ID: " + id );
	Put ( "#Reference", "Reference: " + id );
	Put ( "#Number", id );
	Click ( "#FormOK" );

	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Operation
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Operations" );
	With ( "Operations (cr*" );
	Put ( "#Operation", "Cash Expense" );
	Put ( "#Description", Env.OperationExpense );
	Click ( "#Simple" );
	Put ( "#AccountCr", "10400" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Entry
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
	form = With ( "Entry (cr*" );
	Put ( "#Operation", Env.OperationExpense );
	Click ( "#RecordsContextMenuAdd" );
	
	With ( "Record" );
	Put ( "#AccountDr", "11000" );
	Put ( "#DimDr1", Env.Vendor );
	Put ( "#Amount", "5000" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#RecordsContextMenuAdd" );
	
	With ( "Record" );
	Put ( "#AccountDr", "20000" );
	Put ( "#DimDr1", Env.Vendor );
	Put ( "#Amount", "2000" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#NewVoucher" );
	
	With ( "Cash Voucher" );
	Put ( "#Reason", "Reason: " + id );
	Put ( "#Reference", "Reference: " + id );
	Put ( "#ID", "ID: " + id );
	Click ( "#FormOK" );

	With ( form );
	Click ( "#FormPostAndClose" );
	
	CloseAll ();

	Call ( "Common.StampData", id );

EndProcedure
