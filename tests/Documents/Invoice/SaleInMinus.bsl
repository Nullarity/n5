// Test sales in munus in non-balance-control mode.  and check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0P4" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region Invoice
Call("Documents.Invoice.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date - 86400); // system shouldn't control balances
	Put("#Company", this.Company);
	Put("#Customer", this.Customer);
	Put("#Warehouse", this.Warehouse);
	Put("#Department", this.Department);
	Put("#Memo", id);
	Click("#ItemsTableAdd");
	Put("#ItemsTable / #ItemsItem [1]", this.Item);
	Put("#ItemsTable / #ItemsQuantity [1]", 200);
	Put("#ItemsTable / #ItemsPrice [1]", 15);
endif;
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
#endregion

#region checkQuantity
With ();
Check ( "#TabDoc [ R7C20:R7C21 ]", "200" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Company", "Company " + id );
	this.Insert ( "Warehouse", "Warehouse " + id );
	this.Insert ( "Department", "Department " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCompany
	p = Call ( "Catalogs.Companies.Create.Params" );
	p.Description = this.Company;
	p.BalanceControl = "Control only when online posting is available";
	Call ( "Catalogs.Companies.Create", p );
	#endregion

	#region newDepartment
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Company = this.Company;
	p.Description = this.Department;
	Call ( "Catalogs.Departments.Create", p );
	#endregion

	#region newWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Company = this.Company;
	p.Description = this.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	#endregion
	
	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item;
	row.Quantity = "150";
	row.Price = "7";
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Company = this.Company;
	p.Warehouse = this.Warehouse;
	p.Account = "6111";
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Company = this.Company;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
