// Will accept 100 mdl prepayment and then increase customer debt up to 50 mdl

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A10F" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region adjustDebts
Call ( "Documents.AdjustDebts.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
else
	Commando ( "e1cib/command/Document.AdjustDebts.Create" );
	Set ( "#Customer", this.Customer );
	Click ( "#ApplyVAT" );
	Pick ( "#Option", "Custom Account (Cr)" );
	Set ( "#Account", "6111" );
	Set ( "#Amount", 150 );
	Put ( "#Memo", id );
	Activate ( "#GroupDocuments" );
	Click ( "#Update" );
	With ( "Nullarity" );
	Click ( "#Button0" );
	With ();
	Click ( "#MarkAll" );
	table = Get ( "#Adjustments" );
	Set ( "#AdjustmentsItem", this.Discounts, table );
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
Close ();
With ();
#endregion

#region taxInvoice
Click ( "#NewInvoiceRecord" );
With ();
Clear ( "#Range" );
Set ( "#Number", id );
Click ( "#FormPrint" );
#endregion
Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Discounts", "Discounts " + id );

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

	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Discounts;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region acceptPrepayment
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Date", CurrentDate () - 86400 );
	Put ( "#Customer", this.Customer );
	Set ( "#Amount", 100 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
