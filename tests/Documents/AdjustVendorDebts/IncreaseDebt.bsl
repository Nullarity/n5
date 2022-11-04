// Will give 100 mdl prepayment and then increase our debt up to 50 mdl

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "B10C" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region adjustVendorDebts
Call ( "Documents.AdjustVendorDebts.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
else
	Commando ( "e1cib/command/Document.AdjustVendorDebts.Create" );
	Put ( "#Vendor", this.Vendor );
	Click ( "#ApplyVAT" );
	Pick ( "#Option", "Custom Account (Dr)" );
	Set ( "#Account", "6111" );
	Set ( "#Amount", 150 );
	Put ( "#Memo", id );
	Activate ( "#GroupDocuments" );
	Click ( "#Update" );
	With ( "Contabilizare" );
	Click ( "#Button0" );
	With ();
	Click ( "#MarkAll" );
	Set ( "#AdjustmentsItem", this.Discounts, Get("#Adjustments") );
	Click ( "#AccountingAdd" );
	Accounting = Get ( "#Accounting" );
	Accounting.EndEditRow ();
	Set ( "#AccountingItem [ 1 ]", this.Discounts, Accounting );
	Set ( "#AccountingAmount [ 1 ]", 50, Accounting );
endif;
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Discounts", "Discounts " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Discounts;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region payToVendor
	Commando ( "e1cib/command/Document.VendorPayment.Create" );
	Set ( "#Date", CurrentDate () - 86400 );
	Put ( "#Vendor", this.Vendor );
	Set ( "#Amount", 100 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
