// Create SO (with services) with 10% for early payment
// Sell services
// Receive 90% in advance
// Create 10% discount invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A03C" );
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
	Set("#Memo", id);
endif;
Check ( "#Discount", 40 );
Check ( "#Amount", -40 );
Check ( "#PaymentsApplied", -40 );
Check ( "#BalanceDue", 0 );

// Put wrong discount amount and check error message
Put ("#Discounts / #DiscountsAmount [1]", 50); // 10 more then 40
Click ( "#FormPost" );
Call("Common.CheckPostingError", "The registered discount is exceeded *");
// Update discounts and check records
Click("#DiscountsRefreshDiscounts");
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
