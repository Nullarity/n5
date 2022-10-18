// Will adjust vendor debt to customer prepayment in currency

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0ZD" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region adjustments
Call ( "Documents.AdjustVendorDebts.ListByMemo", id );
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
	Set ( "#Vendor", this.Vendor );
	Pick ( "#Type", "Advance" );
	Set ( "#Receiver", this.Customer );
	Set ( "#Memo", id );
	Click ( "#ApplyVAT" );
	Set ( "#Currency", "MDL" );
	Set ( "#Amount", 100 );
	Set ( "#VendorAccount", "5212" );
	Set ( "#ReceiverAccount", "2212" );
	Set ( "#ContractRate", 21.1879 );
	Set ( "#ReceiverContractRate", 21 );
endtry;
Click ( "#FormPost" );
#endregion

Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Customer", "Customer " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Currency = "USD";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	p.Currency = "EUR";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region payToVendor
	Commando ( "e1cib/command/Document.VendorPayment.Create" );
	Set ( "#Vendor", this.Vendor );
	Set ( "#VendorAccount", "5212" );
	Set ( "#ContractRate", 21.1879 );
	Set ( "#Amount", 100 );
	Click ( "#FormPostAndClose" );
	#endregion
	
	#region receiveAdvance
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Customer", this.Customer );
	Set ( "#CustomerAccount", "2212" );
	Set ( "#AdvanceAccount", "5232" );
	Set ( "#ContractRate", 21 );
	Set ( "#Amount", 100 );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
