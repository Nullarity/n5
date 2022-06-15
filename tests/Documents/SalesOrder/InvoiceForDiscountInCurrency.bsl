// Create SO (with services) with 10% for early payment
// Sell services
// Receive 90% in advance
// Create 10% discount invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0RI" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newSalesOrder
Commando("e1cib/list/Document.SalesOrder");
Clear("#StatusFilter");
Click("#FormCreate");
With();
Put ( "#Customer", this.Customer );
Put ( "#Memo", id );
Check("#Rate", 21);
Put ( "#Currency", "MDL" );
Check("#Rate", 21);
Items = Get ( "!Services" );
Click ( "!ServicesAdd" );
Items.EndEditRow ();
Set ( "!ServicesItem", this.Item, Items );
Set ( "!ServicesQuantity", 40, Items );
Set ( "!ServicesPrice", 10, Items );
Click("#FormSendForApproval");
With();
Click ( "!Button0" );
#endregion

#region approveSO
With();
Click ( "!FormChange" );
With ();
Click ( "!FormCompleteApproval" );
With ();
Click ( "!Button0" );
#endregion

#region sell
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
Put("#Currency", "MDL");
Click ( "#FormPostAndClose" );
#endregion

#region payPO
Call("Documents.Payment.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.Payment.Create");
	Put("#Customer", this.Customer);
	Set("#Amount", 360); // (400 - 10%)
	Set("#Memo", id);
	Set("#Account", "2421");
endif;
Click ( "#FormPost" );
#endregion

#region sendDiscountInvoice
Call("Documents.Invoice.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Customer", this.Customer);
	Put("#Currency", "MDL");
	Set("#Memo", id);
endif;
try
	Check ( "#Discount", 39.9 );
except
	DebugStart ();
endtry;
Check ( "#VAT", -6.72 );
Check ( "#Amount", -39.9 );
Check ( "#ContractAmount", -1.9 );
Check ( "#PaymentsApplied", -1.9 );
Check ( "#BalanceDue", 0 );
Click ( "#FormPost" );
Click("#FormReportRecordsShow");
With ();
CheckTemplate("#TabDoc");
Close();
#endregion

#region createVATrecord
Call("Documents.Invoice.ListByMemo", id);
With();
Click("#FormChange");
With();
Click("#NewInvoiceRecord");
With();
Assert ( Fetch ( "#Discounts / #DiscountsDocument [ 1 ]" ) ).Filled ();
Assert ( Fetch ( "#Discounts / #DiscountsDetail [ 1 ]" ) ).Filled ();
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createTerms
	Commando("e1cib/command/Catalog.PaymentOptions.Create");
	Set("#Description", id);
	Click("#DiscountsAdd");
	table = Get("#Discounts");
	table.EndEditRow ();
	Set ("#DiscountsEdge", 3, table);
	Set ("#DiscountsDiscount", 10, table);
	Click("#FormWriteAndClose");
	Commando("e1cib/command/Catalog.Terms.Create");
	Set("#Description", id);
	Click("#PaymentsAdd");
	table = Get("#Payments");
	table.EndEditRow ();
	Set ("#PaymentsOption", id, table);
	Set ("#PaymentsVariant", "On Delivery", table);
	Set ("#PaymentsPercent", 100, table);
	Click("#FormWriteAndClose");
	#endregion
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Terms = id;
	p.Currency = "USD";
	p.RateType = "Fixed";
	p.Rate = 21;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
