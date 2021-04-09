Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6A957D" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open Cash receipt
// *************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.CashReceipt" );
With ( "Petty Cash Receipt" );
p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = id;
Call ( "Common.Find", p );
Click ( "#FormDocumentJournalPettyCashPrint" );
form = With ();
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );

Run ( "TestEntry", Env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "_Customer: " + ID );
	p.Insert ( "OperationReceipt", "Cash Receipt: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Click ( "#Customer" );
	Put ( "#Description", Env.Customer );
	Put ( "#CodeFiscal", "10005555666" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Customer Payment
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Payment" );
	form = With ( "Customer Payment (*" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Amount", "1000" );
	Put ( "#Method", "Cash" );
	Click ( "#NewReceipt" );
	
	With ( "Cash Receipt" );
	Put ( "#Reason", "Reason: " + id );
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
	Put ( "#Operation", "Cash Receipt" );
	Put ( "#Description", Env.OperationReceipt );
	Click ( "#Simple" );
	Put ( "#AccountDr", "2411" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Entry
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
	form = With ( "Entry (cr*" );
	Put ( "#Operation", Env.OperationReceipt );
	Click ( "#RecordsContextMenuAdd" );
	
	With ( "Record" );
	Put ( "#AccountCr", "5211" );
	Put ( "#DimCr1", Env.Customer );
	Put ( "#Amount", "5000" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#RecordsContextMenuAdd" );
	
	With ( "Record" );
	Put ( "#AccountCr", "5212" );
	Put ( "#DimCr1", Env.Customer );
	Put ( "#Amount", "2000" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#NewReceipt" );
	
	With ( "Cash Receipt" );
	Put ( "#Reason", "Reason: " + id );
	Put ( "#Reference", "Reference: " + id );
	Click ( "#FormOK" );

	With ( form );
	Click ( "#FormPostAndClose" );
	
	CloseAll ();

	Call ( "Common.StampData", id );

EndProcedure
