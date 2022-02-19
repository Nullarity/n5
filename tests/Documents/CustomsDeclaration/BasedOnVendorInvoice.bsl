// Create Vendor Invoice and Customs Declaration

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0N2" );
getEnv ( id );
createEnv ();

Call ("Documents.VendorInvoice.ListByMemo", id);
Click ( "#FormDocumentCustomsDeclarationCreateBasedOn" );
With ();
Put ( "#Customs", this.Customs );
Put ( "#VATAccount", "5344" );

// Delete an item from group1
table = Activate ( "#CustomGroups" );
Click ( "#ItemsContextMenuDelete" );

// Add group2 and assign that item
Click ( "#Add" );
table.EndEditRow ();
Set ( "#CustomGroupsCustomsGroup", this.CustomsGroup, table );
Click ( "#ItemsAddFromInvoice" );
With ();
Click ( "#FormChoose" ); // Should be second invoice by default
With ();
Click ( "#FormSelect" );
With ();

Click ( "#ShowDetails" );
table = Activate ( "#Charges" );
search = new Map ();
search.Insert ( "Charge", "Таможенная пошлина, 020" );
table.GotoFirstRow ();
table.GotoRow ( search, RowGotoDirection.Down );
Activate ( "#ChargesCost", table );
Put ( "#ChargesCost", "Expense", table );
Put ( "#ChargesExpenseAccount", "7141", table );
Put ( "#ChargesDim1", this.Expense, table );
Set ( "#ChargesDim2", this.Department, table );
Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "Customs Declaration (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;

Close ( copy );

Run ( "Logic" );
Run ( "LogicImport", this );

Procedure getEnv ( ID )

	this.Insert ( "ID", ID );
	date = BegOfDay ( CurrentDate () );
	this.Insert ( "Date", date );
	this.Insert ( "CurDate", CurrentDate () );
	this.Insert ( "Warehouse", "Warehouse: " + ID );
	this.Insert ( "Expense", "Expense: " + ID );
	this.Insert ( "Department", "Department: " + ID );
	this.Insert ( "Vendor", "Vendor: " + ID );
	this.Insert ( "Customs", "Customs: " + ID );
	this.Insert ( "CustomsGroup", "CustomsGroup: " + ID );
	this.Insert ( "Payments", getPayments () );
	this.Insert ( "Item1", "Item1: " + ID );
	this.Insert ( "Item2", "Item2: " + ID );
	this.Insert ( "Goods", getGoods () );

EndFunction

Function getGoods ();

	goods = new Array ();
 	row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
 	row.Item = this.Item1;
	row.Quantity = "1";
	row.Price = "1000";
	goods.Add ( row );

	row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	row.Item = this.Item2;
	row.Quantity = "1";
	row.Price = "100";
	goods.Add ( row );

	return goods;

EndFunction

Function getPayments ();

	payments = new Array ();
 	row = Call ( "Catalogs.CustomsGroups.Create.Row" );
	row.Payment = "Плата за таможенные процедуры, 010";
	row.Percent = 10;
	payments.Add ( row );

	row = Call ( "Catalogs.CustomsGroups.Create.Row" );
	row.Payment = "Таможенная пошлина, 020";
	row.Percent = 5;
	payments.Add ( row );
	
	row = Call ( "Catalogs.CustomsGroups.Create.Row" );
	row.Payment = "НДС, 030";
	payments.Add ( row );

	return payments;

EndFunction

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newWarehouse
	Call ( "Catalogs.Warehouses.Create", this.Warehouse );
	#endregion
	
	#region newDepartment
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = this.Department;
	Call ( "Catalogs.Departments.Create", p );
	#endregion
	
	#region newExpense
	Call ( "Catalogs.Expenses.Create", this.Expense );
	#endregion
	
	#region newVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	p.Currency = "CAD";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region newCustoms
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Customs;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region newCustomsGroup
	p = Call ( "Catalogs.CustomsGroups.Create.Params" );
	p.Description = this.CustomsGroup;
	p.Payments = this.Payments;
	Call ( "Catalogs.CustomsGroups.Create", p );
	#endregion
	
	#region newItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item1;
    p.UseCustomsGroup = true;
    p.CustomsGroup = this.CustomsGroup;
    p.CountPackages = false;
	p.CostMethod = "FIFO";
	Call ( "Catalogs.Items.Create", p );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item2;
    p.UseCustomsGroup = true;
    p.CustomsGroup = this.CustomsGroup;
    p.CountPackages = true;
	p.CostMethod = "FIFO";
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region newVendorInvoice
	p = Call ( "Documents.VendorInvoice.Buy.Params" );
	p.Date = this.Date - 86400;
	p.Vendor = this.Vendor;
	p.Warehouse = this.Warehouse;
	p.Items = this.Goods;
	p.Import = true;
	p.ID = id;
	Call ( "Documents.VendorInvoice.Buy", p );

	With ( "Vendor invoice*" );
	Put ( "#Memo", id );
	Put ( "#Rate", "15.1779" );
	Click ( "#FormPost" );
	#endregion

	CloseAll ();
	
	RegisterEnvironment ( id );

EndProcedure
