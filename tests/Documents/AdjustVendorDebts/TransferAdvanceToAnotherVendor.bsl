// Will pay in advance to vendor1 and then transfer that debt to vedor2

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "B0Z0" );
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
	Pick ( "#Option", "Vendor" );
	Set ( "#Vendor", this.Vendor1 );
	Pick ( "#Type", "Advance" );
	Set ( "#Receiver", this.Vendor2 );
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
	this.Insert ( "Vendor1", "Vendor1 " + id );
	this.Insert ( "Vendor2", "Vendor2 " + id );
	this.Insert ( "Advance", "Advance " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createVendors
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor1;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	p.Description = this.Vendor2;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region payToVendor1
	Commando ( "e1cib/command/Document.VendorPayment.Create" );
	Set ( "#Vendor", this.Vendor1 );
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
