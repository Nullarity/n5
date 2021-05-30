// User should be prevented from posting invoice without closing prepayment
// if PaymentBalance is less then invoice amount.
// Scenario:
// Create SO $20
// Receive a prepayment $15
// Create an invoice $10 and check if system reject posting such invoice.
// Why? Because we have only $5 left to be invoiced without prepayment

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A005" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newSalesOrder
Commando("e1cib/list/Document.SalesOrder");
Clear("#StatusFilter");
Click("#FormCreate");
With();
Put ( "#Customer", this.Customer );
Put ( "#VATUse", 0 );
Put ( "#Memo", id );
Items = Get ( "!ItemsTable" );
Click ( "!ItemsTableAdd" );
Items.EndEditRow ();
Set ( "!ItemsItem", this.Item, Items );
Set ( "!ItemsQuantityPkg", 20, Items );
Set ( "!ItemsPrice", 1, Items );

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

#region paySO
With ();
Click ( "#FormDocumentPaymentCreateBasedOn" );
With ();
Set("#Amount", 15);
Next();
Click ( "!FormPostAndClose" );
#endregion

#region checkInvoive
Commando("e1cib/command/Document.Invoice.Create");
Set("#Customer", this.Customer);
Next ();
Click ( "!FormPost" );
error = "* 15.00 USD *";
Call ( "Common.CheckPostingError", error );
Items = Get ( "!ItemsTable" );
Set ( "#ItemsQuantity", 5, Items );
Click ( "!FormPost" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Terms = "Due on receipt";
	p.Currency = "USD";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region CreateVI
	Commando("e1cib/command/Document.VendorInvoice.Create");
	Set ( "!Vendor", this.Vendor );
	Items = Get ( "!ItemsTable" );
	Click ( "!ItemsTableAdd" );
	Items.EndEditRow ();
	Set ( "!ItemsItem", this.Item, Items );
	Set ( "!ItemsQuantityPkg", 1000, Items );
	Set ( "!ItemsPrice", 3, Items );
	Click ( "!FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
