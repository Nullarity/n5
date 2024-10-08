﻿// Check cost sequence

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A126" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region changeReceipt
Call ( "Documents.ReceiveItems.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
table = Get ( "#Items" );
Set ( "#ItemsPrice [1]", 10, table );
Set ( "#ItemsPrice [2]", 40, table );
Click ( "#FormPostAndClose" );
#endregion

#region restoreCost
Commando ( "e1cib/app/DataProcessor.Cost" );
Click ( "#Restore" );
Pause ( 2 * __.Performance );
Close ();
#endregion

#region checkInvoice
Call ( "Documents.Invoice.ListByMemo", id );
With ();
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region resetCost
	Commando ( "e1cib/app/DataProcessor.Cost" );
	Click ( "#FormReset" );
	Close ();
	#endregion
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item1;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item2;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item1;
	row.Quantity = 150;
	row.Price = 7;
	items.Add ( row );
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item2;
	row.Quantity = 25;
	row.Price = 30;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Account = "6111";
	p.Items = items;
	p.Memo = id;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region invoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date);
	Put("#Customer", this.Customer);
	Put("#Memo", id);
	table = Get ( "#ItemsTable" );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Set ( "#ItemsQuantity", 50, table );
	Set ( "#ItemsPrice", 15, table );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Set ( "#ItemsQuantity", 10, table );
	Set ( "#ItemsPrice", 60, table );
	Click ( "#FormPostAndClose" );
	#endregion
	RegisterEnvironment ( id );

EndProcedure
