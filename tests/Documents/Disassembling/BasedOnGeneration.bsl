Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
warehouse = "_Assembling Warehouse";

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = date - 86400;
p.Warehouse = warehouse;
p.Account = "8111";
p.Expenses = "_Assembling";

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

Call ( "Common.OpenList", Meta.Documents.Assembling );
Click ( "#FormCreate" );
form = With ( "Assembling (create)" );

Set ( "#Warehouse", warehouse );
Choose ( "#Set" );
name = "_Set: " + date;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Items;
params.Search = name;
creation = Call ( "Catalogs.Items.Create.Params" );
creation.Description = name;
creation.CountPackages = false;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ( form );

Set ( "#Quantity", "25" );

table = Activate ( "#Items" );
Call ( "Table.AddEscape", table );
for each row in p.Items do
	Click ( "#ItemsAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
enddo;
Call ( "Table.CopyEscapeDelete", table );

Click ( "#FormPost" );
Click ( "#FormDocumentDisassemblingCreateBasedOn" );