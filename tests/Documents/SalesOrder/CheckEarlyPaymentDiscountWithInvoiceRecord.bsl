﻿// Create SO with 2% for early payment
// Receive a 100% prepayment
// Sell items and check if reverse transactions come up
// Check Record Invoice with negative amount for discount
// Unload this Invoice to e-factura

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A05A" );
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
Items = Get ( "!ItemsTable" );
Click ( "!ItemsTableAdd" );
Items.EndEditRow ();
Set ( "!ItemsItem", this.Item, Items );
Set ( "!ItemsQuantityPkg", 40, Items );
Set ( "!ItemsPrice", 10, Items );
Click ( "!ItemsTableAdd" );

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
Click ( "!FormPostAndClose" );
#endregion

#region sell
Call("Documents.Invoice.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.Invoice.Create");
	Set("#Customer", this.Customer);
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

#region vatRecord
Close();
With();
Click("#NewInvoiceRecord");
With();
Check("#VAT", 65.34);
Check("#Amount", 392);
Clear ("#Range");
Set("#Number", Call("Common.GetID"));
Set("#Memo", id);
Click("#FormPrint");
With();
Call("Documents.SalesOrder.CheckInvoiceRecordWithPaymentDiscount");
#endregion

#region unloadToEFactura
Call("Documents.InvoiceRecord.ListByMemo", id);
With();
Click("#FormChange");
With();
Put("#Status", "Saved");
Click("#FormWrite");
Choose ( "#Range" );
With ();
GotoRow("#List", "Range", id);
Click ( "#FormChoose" );
With();
Click ( "#FormWriteAndClose" );
CheckErrors ();
With();
Click("#FormDataProcessorUnloadInvoicesOpen");
With();
Click ( "#IncludeWaiting" );
Click("#UnmarkAll");
GotoRow(Get("#Invoices"), "Customer", this.Customer);
Click("#InvoicesUnload");
path = __.Files + "efactura.xml";
Set ( "#Path", path );
Click ( "#InvoicesUnloadButton" );
Pause(4);
CheckErrors();
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
	p.CodeFiscal = id;
	p.BankAccount = "ACC" + id;
	p.PaymentAddress = "Address " + id;
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
	p.Unit = "UT";
	p.Capacity = 1;
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

	#region createRange
	Commando("e1cib/command/Catalog.Ranges.Create");
	Put ( "#Type", "Invoices Online" );
	Set ( "#Length", 9 );
	Set ( "#Description", id );
	Click ( "#WriteAndClose" );
	CheckErrors ();

	Commando("e1cib/command/Document.EnrollRange.Create");
	Set ( "#Range", id );
	Click ( "#FormWriteAndClose" );
	CheckErrors ();
	#endregion

	RegisterEnvironment ( id );

EndProcedure
