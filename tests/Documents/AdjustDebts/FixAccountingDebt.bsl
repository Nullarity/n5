// Will sell services for 2000 lei (100$ x 20), then accept the payment 1900 ley (100$ x 19)
// and then adjust debt 100 lei to make the debt even.

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0T5" );
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
	Set ( "#Option", "Accounting (Dr)" );
	Set ( "#Account", "6111" );
	Put ( "#Currency", "mdl" );
	Set ( "#ContractRate", 19 ); // the same rate as payment is
	Put ( "#Memo", id );
	Set ( "#Amount", 100 );
	Click ( "#AccountingAdd" );
	Accounting = Get ( "#Accounting" );
	Accounting.EndEditRow ();
	Set ( "#AccountingItem [ 1 ]", this.Discounts, Accounting );
	Set ( "#AccountingAmount [ 1 ]", 5.26, Accounting ); // 5.26 = 100 / 19
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
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );
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
	p.Currency = "usd";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createDiscounts
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Discounts;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region invoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date-86400*2);
	Put("#Customer", this.Customer);
	Put("#Memo", id);
	Set("#Rate", 20);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 100, table );
	Click ( "#FormPostAndClose" );
	#endregion

	#region acceptPayment
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Date", CurrentDate () - 86400 );
	Pick ( "#Customer", this.Customer );
	Set ( "#ContractRate", 19 );
	Set ( "#Amount", 1900 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
