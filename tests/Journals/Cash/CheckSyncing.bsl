// Scenario:
// - Open list of Customer Payments and clean filters
// - Create & Post a new Customer Payment
// - Open Petty Cash journal
// - Check Posting status of that Receipt
// - Unpost Receipt
// - Open Customer Payments
// - Check Status
// - Mark Customer Payments for deletion
// - Open Petty Cash and check if deletion mark = true
// - Remove deletion mark from Receit
// - Open Customer Payment and check if deletion mark = false

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25BD2DBF" );
env = getEnv ( id );
createEnv ( env );
docID = env.DocumentID;

// ***********************
// Create Customer Payment
// ***********************

Commando ( "e1cib/list/Document.Payment" );
paymentsList = With ( "Customer Payments" );

Click ( "#FormCreate" );
form = With ( "Customer Payment (cr*" );

Put ( "#Customer", env.Customer );
Pick ( "#Method", "Cash" );
Set ( "#Amount", "300" );
Set ( "#Memo", docID );
Click ( "#FormPostAndClose" );

// ************************
// Open Petty Chash Journal
// ************************

Commando ( "e1cib/list/DocumentJournal.Cash" );
cashList = With ( "Petty Cash" );
GotoRow ( "#List", "Memo", docID );
Click ( "#FormUndoPosting" );

// *******************************************************
// Activate Customer Payments: document should be unposted
// *******************************************************

With ( paymentsList, true );
Click ( "#FormRefresh" );

Click ( "#FormReportRecordsShow" );
With ( "Records: *" );
label = Fetch ( "#TabDoc [R2C2]" );
if ( StrFind ( label, "Customer Payment" ) <> 1 ) then
	Stop ( "Customer Payment should be unposted" );
endif;
Close ();

// *************************************************
// Activate Petty Cash & post
// *************************************************

With ( cashList, true );
Click ( "#FormPost" );

// *******************************************************
// Activate Customer Payments: document should be posted
// *******************************************************

With ( paymentsList, true );
Click ( "#FormRefresh" );

Click ( "#FormReportRecordsShow" );
With ( "Records: *" );
label = Fetch ( "#TabDoc [R2C2]" );
if ( StrFind ( label, "Customer Payment" ) = 1 ) then
	Stop ( "Customer Payment should be posted" );
endif;
Close ();

// *************************************************
// Mark Customer Payment for deletion
// *************************************************

With ( paymentsList );
Click ( "#FormSetDeletionMark" );
Click ( "Yes", Forms.Get1C () );

// ******************************************************
// Activate Petty Cash: deletion mark should be installed
// ******************************************************

With ( cashList, true );
Click ( "#FormRefresh" );
Click ( "#FormPost" );
Click ( "OK", Forms.Get1C () ); // A document marked for deletion cannot be posted!
Click ( "#FormSetDeletionMark" );
Click ( "Yes", Forms.Get1C () ); // Deletion mark removing

// *******************************************************
// Activate Customer Payments: document should be unposted
// *******************************************************

With ( paymentsList, true );
Click ( "#FormRefresh" );

Click ( "#FormReportRecordsShow" );
With ( "Records: *" );
label = Fetch ( "#TabDoc [R2C2]" );
if ( StrFind ( label, "Customer Payment" ) <> 1 ) then
	Stop ( "Customer Payment should be unposted" );
endif;
Close ();

With ( paymentsList );
Click ( "#FormPost" ); // Posting just in case document is still marked for deletion
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "DocumentID", Call ( "Common.GetID" ) );
	p.Insert ( "Customer", "Customer " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	RegisterEnvironment ( id );

EndProcedure
