// Will adjust customer advance to vendor prepayment

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0YM" );
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
	Pick ( "#Option", "Vendor" );
	Set ( "#Customer", this.Customer );
	Pick ( "#Type", "Advance" );
	Set ( "#Receiver", this.Vendor );
	Set ( "#Memo", id );
	Click ( "#ApplyVAT" );
	Set ( "#Amount", 100 );
endtry;
Click ( "#FormPost" );
#endregion

Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
Run ( "CheckReconciliation", this );

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Vendor", "Vendor " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region payToVendor
	Commando ( "e1cib/command/Document.VendorPayment.Create" );
	Set ( "#Vendor", this.Vendor );
	Set ( "#Amount", 100 );
	Click ( "#FormPostAndClose" );
	#endregion

	#region receiveAdvance
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Customer", this.Customer );
	Set ( "#Amount", 100 );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
