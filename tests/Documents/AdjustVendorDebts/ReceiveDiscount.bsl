// Will receive a discount from vendor

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0YW" );
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
	Set ( "#Vendor", this.Vendor );
	Click ( "#ApplyVAT" );
	Pick ( "#Option", "Custom Account (Dr)" );
	Set ( "#Account", "6111" );
	Set ( "#Amount", 100 );
	Put ( "#Memo", id );
	Click ( "#AccountingAdd" );
	Accounting = Get ( "#Accounting" );
	Accounting.EndEditRow ();
	Set ( "#AccountingItem [ 1 ]", this.Discounts, Accounting );
	Set ( "#AccountingAmount [ 1 ]", 100, Accounting );
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

	RegisterEnvironment ( id );

EndProcedure
