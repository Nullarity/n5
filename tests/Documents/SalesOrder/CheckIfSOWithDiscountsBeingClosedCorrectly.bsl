// Check If SO With Discounts Being Closed Correctly

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2CF2DBBE" ) );
getEnv ();                                            
createEnv ();

#region newQuote
Commando("e1cib/command/Document.Quote.Create");
Set ( "!Customer", this.Customer );
Set ( "!DueDate", Format ( CurrentDate() + 86400, "DLF=D" ) );
Items = Get ( "!Items" );
Click ( "!ItemsAdd" );
Items.EndEditRow ();
Set ( "!ItemsItem", this.Item, Items );
Set ( "!ItemsQuantityPkg", 1, Items );
Set ( "!ItemsPrice", 10, Items );
Set ( "!ItemsDiscountRate", 5, Items );
Click ( "!FormDocumentSalesOrderCreateBasedOn" );
With ();
Click ( "!Button0" );
#endregion

#region approveSO
With();
Click ( "!FormSendForApproval" );
With ();
Click ( "!Button0" );
With ( "Quote *" );
Click ( "!Links[1]" );
With ();
Click ( "!FormCompleteApproval" );
With ();
Click ( "!Button0" );
#endregion

#region paySO
With ( "Quote *" );
Click ( "!Links[1]" );
With ( "Sales Order *" );
Click ( "!FormPayment" );
With ();
Click ( "!FormPostAndClose" );
#endregion

#region checkInvoive1
Commando("e1cib/command/Document.Invoice.Create");
Set("#Customer", this.Customer);
Next ();
Items = Get ( "!ItemsTable" );
Assert ( Call("Table.Count", Items ) ).Not_ ().Empty ();
Click ( "!FormPostAndClose" );
#endregion

#region checkInvoive2
Commando("e1cib/command/Document.Invoice.Create");
Set("#Customer", this.Customer);
Next ();
Items = Get ( "!ItemsTable" );
Assert ( Call("Table.Count", Items ) ).Empty ();
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
