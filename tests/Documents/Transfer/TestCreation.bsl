Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
sender = "_Transfer Sender";
receiver = "_Transfer Receiver";

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = date - 86400;
p.Warehouse = sender;
p.Account = "8111";
p.Expenses = "_Transfer";

goods = new Array ();

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item1: " + date;
row.CountPackages = false;
row.Quantity = "150";
row.Price = "7";
goods.Add ( row );

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item2, countPkg: " + date;
row.CountPackages = true;
row.Quantity = "65";
row.Price = "70";
goods.Add ( row );

p.Items = goods;
Call ( "Documents.ReceiveItems.Receive", p );

Call ( "Common.OpenList", Meta.Documents.Transfer );
Click ( "#FormCreate" );
form = With ( "Transfer (create)" );

Call ( "Common.CheckCurrency", form );

Set ( "#Sender", sender );

Choose ( "#Receiver" );
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Warehouses;
params.Search = receiver;
Call ( "Common.Select", params );

With ( form );
Set ( "#Receiver", receiver );

table = Activate ( "#ItemsTable" );
Call ( "Table.AddEscape", table );
for each row in p.Items do
	Click ( "#ItemsTableAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
enddo;
Call ( "Table.CopyEscapeDelete", table );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Transfer *" );
Call ( "Common.CheckLogic", "#TabDoc" );

// ***********************************
// Print with and without prices
// ***********************************

With ( form );
Click ( "#FormDocumentTransferTransfer" );
Close ( "Transfer: Print" );

With ( form );
Click ( "#ShowPrices" );
Click ( "#FormWrite" );
With ( form );
Click ( "#FormDocumentTransferTransfer" );
