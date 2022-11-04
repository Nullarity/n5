// Create PO with 2% for early payment
// Receive a 100% prepayment
// Buy items and check if reverse transactions come up

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A11I" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newPurchaseOrder
Commando("e1cib/list/Document.PurchaseOrder");
Click("#FormCreate");
With();
Put ( "#Vendor", this.Vendor );
Put ( "#Memo", id );
Items = Get ( "!ItemsTable" );
Click ( "!ItemsTableAdd" );
Items.EndEditRow ();
Set ( "!ItemsItem", this.Item, Items );
Set ( "!ItemsQuantityPkg", 40, Items );
Set ( "!ItemsPrice", 10, Items );
Click("#FormPostAndClose");
#endregion

#region payPO
With ();
Click ( "#FormDocumentVendorPaymentCreateBasedOn" );
With ();
Set ( "#Amount", 392 );
Click ( "!FormPostAndClose" );
#endregion

#region buy
Call("Documents.VendorInvoice.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.VendorInvoice.Create");
	Set("#Vendor", this.Vendor);
	Set("#Memo", id);
endif;
Click ( "#FormPost" );
Check("#Discount", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
Click("#FormReportRecordsShow");
With ();
CheckTemplate ( "#TabDoc" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Item", "Item " + id );

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

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Unit = "UT";
	p.Capacity = 1;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
