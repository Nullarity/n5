// Test PO Report

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "A19L");
this.Insert("ID", id);
getEnv();
createEnv();

#region createPO
Call ( "Documents.PurchaseOrder.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
else
	Commando("e1cib/command/Document.PurchaseOrder.Create");
	Put("#Vendor", this.Vendor);
	Put("#Memo", id);
	
	table = Get ( "#ItemsTable" );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Set ( "#ItemsQuantity", 500, table );
	Set ( "#ItemsPrice", 4, table );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Set ( "#ItemsQuantity", 800, table );
	Set ( "#ItemsPrice", 6, table );
	Click ( "#JustSave" );
	//Click ( "#FormPost" );
	//Click ( "#FormPostAndClose" );
endif;
#endregion

#region report
Click ( "#FormReportPurchaseOrderShow" );
#endregion

Procedure getEnv()
	
	id = this.ID;
	today = CurrentDate();
	this.Insert("Today", today);
	lastYear = Year(today) - 1;
	this.Insert("LastYear", Date(lastYear, 1, 1));
	this.Insert("LastJune", Date(lastYear, 6, 1));
	this.Insert("Item1", "Item1 " + id);
	this.Insert("Item2", "Item2 " + id);
	this.Insert("Vendor", "Vendor " + id);
	this.Insert("Customer", "Customer " + id);
	
EndProcedure

Procedure createEnv()
	
	id = this.ID;
	If (EnvironmentExists(id)) Then
		Return;
	EndIf;
	
	#region createVendor
	p = Call("Catalogs.Organizations.CreateVendor.Params");
	p.Description = this.Vendor;
	Call("Catalogs.Organizations.CreateVendor", p);
	#endregion
	
	#region createCustomer
	p = Call("Catalogs.Organizations.CreateCustomer.Params");
	p.Description = this.Customer;
	Call("Catalogs.Organizations.CreateCustomer", p);
	#endregion
	
	#region createItems
	p = Call("Catalogs.Items.Create.Params");
	p.Description = this.Item1;
	Call("Catalogs.Items.Create", p);
	p.Description = this.Item2;
	Call("Catalogs.Items.Create", p);
	#endregion

	#region receiveItems
	items = new Array();
	row = Call("Documents.ReceiveItems.Receive.Row");
	row.Item = this.Item1;
	row.Quantity = 150;
	row.Price = 7;
	items.Add(row);
	row = Call("Documents.ReceiveItems.Receive.Row");
	row.Item = this.Item2;
	row.Quantity = 200;
	row.Price = 10;
	items.Add(row);
	p = Call("Documents.ReceiveItems.Receive.Params");
	p.Date = this.LastYear;
	p.Account = "6111";
	p.Items = items;
	Call("Documents.ReceiveItems.Receive", p);
	#endregion

	#region invoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.LastJune );
	Put("#Customer", this.Customer);
	Pick ( "#VATUse", "Not Applicable" );
	Put("#Memo", id);
	
	table = Get ( "#ItemsTable" );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Set ( "#ItemsQuantity", 5, table );
	Set ( "#ItemsPrice", 25, table );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Set ( "#ItemsQuantity", 15, table );
	Set ( "#ItemsPrice", 35, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment(id);
	
EndProcedure
