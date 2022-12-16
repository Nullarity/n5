// Check cost sequence

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A129" );
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

#region checkTransfer
Call ( "Documents.Transfer.ListByMemo", id );
With ();
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Warehouse", "Warehouse " + id );
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
	
	#region newWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
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

	#region transfer
	Commando("e1cib/command/Document.Transfer.Create");
	Put("#Date", this.Date);
	Put("#Receiver", this.Warehouse);
	Put("#Memo", id);
	table = Get ( "#ItemsTable" );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Set ( "#ItemsQuantity", 50, table );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Set ( "#ItemsQuantity", 10, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
