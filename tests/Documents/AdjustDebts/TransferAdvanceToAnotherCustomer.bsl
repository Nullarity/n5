// Will receive an advance from customer1 and then transfer that advance to customer2

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A10E" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region adjustments
Call ( "Documents.AdjustDebts.ListByMemo", id );
try
	Click ( "#FormChange" );
	With ();
	try
		Click ( "#FormUndoPosting" );
	except
	endtry;	
except
	With ();
	Click ( "#FormCreate" );
	With ();
	Pick ( "#Option", "Customer" );
	Set ( "#Customer", this.Customer1 );
	Pick ( "#Type", "Advance" );
	Set ( "#Receiver", this.Customer2 );
	Set ( "#Memo", id );
	Set ( "#Amount", 100 );
	AccountingReceiver = Get ( "#AccountingReceiver" );
	Click ( "#AccountingReceiverAdd" );
	Set ( "#AccountingReceiverAmount", 100, AccountingReceiver );
endtry;
Click ( "#FormPost" );
#endregion

Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer1", "Customer1 " + id );
	this.Insert ( "Customer2", "Customer2 " + id );
	this.Insert ( "Advance", "Advance " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomers
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer1;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	p.Description = this.Customer2;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion
	
	#region advanceFromCustomer
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Customer", this.Customer1 );
	Set ( "#Amount", 100 );
	Click ( "#FormPostAndClose" );
	#endregion

	#region createAdvanceItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Advance;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
