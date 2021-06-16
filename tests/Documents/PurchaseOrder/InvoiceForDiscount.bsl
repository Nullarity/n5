// Create PO (with services) with 10% for early payment
// Purchase services
// Pay 90% in advance
// Receive 10% discount invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A03B" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newPurchaseOrder
Commando("e1cib/list/Document.PurchaseOrder");
Click("#FormCreate");
With();
Put ( "#Vendor", this.Vendor );
Put ( "#Memo", id );
Items = Get ( "!Services" );
Click ( "!ServicesAdd" );
Items.EndEditRow ();
Set ( "!ServicesItem", this.Item, Items );
Set ( "!ServicesQuantity", 40, Items );
Set ( "!ServicesPrice", 10, Items );
Click("#FormPostAndClose");
#endregion

#region buy
Commando("e1cib/command/Document.VendorInvoice.Create");
Put("#Vendor", this.Vendor);
Items = Get ( "!Services" );
Set ( "#ServicesAccount", "7121", Items );
Set ( "!ServicesExpense", "Others", Items );
Click ( "#FormPostAndClose" );
#endregion

#region payPO
Call("Documents.VendorPayment.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.VendorPayment.Create");
	Put("#Vendor", this.Vendor);
	Set("#Amount", 360); // (400 - 10%)
	Set("#Memo", id);
endif;
Click ( "#FormPost" );
#endregion

#region receiveDiscountInvoice
Call("Documents.VendorInvoice.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.VendorInvoice.Create");
	Put("#Vendor", this.Vendor);
	Set("#Memo", id);
endif;
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
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
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
	
	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	p.Terms = id;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
