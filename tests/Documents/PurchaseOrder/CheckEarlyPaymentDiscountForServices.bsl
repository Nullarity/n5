// Create PO (with services) with 2% for early payment
// Pay 100% in advance
// Purchase services and check if reverse transactions come up

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A02Z" );
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

#region payPO
With ();
Click ( "#FormDocumentVendorPaymentCreateBasedOn" );
With ();
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
	Put("#Vendor", this.Vendor);
	Items = Get ( "!Services" );
	Set ( "#ServicesAccount", "7121", Items );
	Set ( "!ServicesExpense", "Others", Items );
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
	this.Insert ( "Item", "Service " + id );

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
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
