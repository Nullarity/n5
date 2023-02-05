// Will sell services for 2000 lei (100$ x 20), then accept the payment 1900 ley (100$ x 19).
// Will accept prepayment 2000 lei (100$ x 20), then sell services for 1960 lei (100$ x 19.6).
// Finally, will move his debt to another contract

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A140" );
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
	Set ( "#Option", "Customer" );
	Click ( "#AmountDifference" );
	Set ( "#Customer", this.Customer );
	Set ( "#Receiver", this.Customer );
	Set ( "#ReceiverContract", this.LocalContract );
	Set ( "#ContractRate", 19 ); // the same rate as payment was
	Put ( "#Memo", id );
	Set ( "#Amount", 60 );
	Click ( "#AccountingReceiverAdd" );
	Accounting = Get ( "#AccountingReceiver" );
	Accounting.EndEditRow ();
	Set ( "#AccountingReceiverAmount [ 1 ]", 60, Accounting );
	Set ( "#AccountingReceiverPaymentOption [ 1 ]", "no discounts", Accounting );
endif;

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Discounts", "Discounts " + id );
	this.Insert ( "LocalContract", "Local Currency" );

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
	p.MonthlyAdvances = true;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	Commando ( "e1cib/list/Catalog.Organizations" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = this.Customer;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ();
	Click ( "Contracts", GetLinks () ); 
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Description", this.LocalContract );
	Click ( "#FormWriteAndClose" );
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
	Put ( "#Customer", this.Customer );
	Set ( "#ContractRate", 19 );
	Set ( "#Amount", 1900 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion

	#region acceptPrepayment
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Date", CurrentDate () - 86300 );
	Put ( "#Customer", this.Customer );
	Set ( "#ContractRate", 20 );
	Set ( "#Amount", 2000 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion

	#region invoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date-86000);
	Put("#Customer", this.Customer);
	Put("#Memo", id);
	Set("#Rate", 19.6);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 100, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
