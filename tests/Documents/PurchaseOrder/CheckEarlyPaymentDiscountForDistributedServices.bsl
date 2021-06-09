// Reveive Items from Vendor
// Create PO (with services) with 2% for early payment
// Receive a 100% prepayment
// Purchase services and distribure them to items
// Check if reverse transactions come up

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A01O" );
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
Set ( "!ServicesItem", this.Service, Items );
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
	Click("#ServicesIntoItems");
	Choose("#ServicesIntoDocument");
	With();
	Put("#VendorFilter", this.Manufacture);
	Click("#FormChoose");
	With();
	Set("#Memo", id);
endif;
Click ( "#FormPost" );
Check("#Benefit", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
Click("#FormReportRecordsShow");
With ();
CheckTemplate ( "#TabDoc" );
#endregion

#region reconciliationReport
p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Reconciliation Statement";
filters = new Array ();
item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
today = CurrentDate ();
item.ValueFrom = Format ( BegOfYear(today), "DLF=D");
item.ValueTo = Format ( EndOfYear(today), "DLF=D");
filters.Add ( item );
item = Call ( "Common.Report.Filter" );
item.Name = "Organization";
item.Value = this.Vendor;
filters.Add ( item );
item = Call ( "Common.Report.Filter" );
item.Name = "Language";
item.Value = "English";
filters.Add ( item );
p.Filters = filters;
Call ( "Common.Report", p );
With ();
Call ( "Documents.PurchaseOrder.CheckReconciliationAfterDiscountAndDistributedServices" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Manufacture", "Manufacture " + id );
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createVendors
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Manufacture;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region CreateVI
	Commando("e1cib/command/Document.VendorInvoice.Create");
	Set ( "!Vendor", this.Manufacture );
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
