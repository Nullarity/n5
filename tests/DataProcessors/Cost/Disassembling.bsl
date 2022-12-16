// Check cost sequence

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A12J" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region changeReceipt
Call ( "Documents.ReceiveItems.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
table = Get ( "#Items" );
Set ( "#ItemsPrice [1]", 800, table );
Click ( "#FormPostAndClose" );
#endregion

#region restoreCost
Commando ( "e1cib/app/DataProcessor.Cost" );
Click ( "#Restore" );
Pause ( 2 * __.Performance );
Close ();
#endregion

#region checkDisassembling
Call ( "Documents.Disassembling.ListByMemo", id );
With ();
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );
	this.Insert ( "Item3", "Item3 " + id );

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
	
	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item1;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item2;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Item3;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item3;
	row.Quantity = 1;
	row.Price = 700;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Account = "6111";
	p.Items = items;
	p.Memo = id;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region disassembling
	Commando("e1cib/command/Document.Disassembling.Create");
	Put("#Date", this.Date);
	Put("#Memo", id);
	Put("#Set", this.Item3);
	Put("#QuantityPkg", 1);
	table = Get ( "#Items" );
	Click  ( "#ItemsAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Set ( "#ItemsQuantity", 50, table );
	Set ( "#ItemsCostRate", 50, table );
	Click  ( "#ItemsAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Set ( "#ItemsQuantity", 10, table );
	Set ( "#ItemsCostRate", 50, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
