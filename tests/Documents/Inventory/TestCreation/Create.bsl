id = _;
date = CurrentDate ();
warehouse = "_Inventory Warehouse: " + date;

if ( Call ( "Common.AppIsCont" ) ) then
	expenseAccount = "7141";
else
	expenseAccount = "8111";
endif;


p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = date - 86400;
p.Warehouse = warehouse;
p.Account = expenseAccount;
p.Expenses = "_Inventory";

goods = new Array ();

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item1: " + id;
row.CountPackages = false;
row.Quantity = "150";
row.Price = "7";
goods.Add ( row );

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item2, countPkg: " + id;
row.CountPackages = true;
row.Quantity = "65";
row.Price = "70";
goods.Add ( row );

p.Items = goods;
Call ( "Documents.ReceiveItems.Receive", p );

// ****************************
// Create Inventory
// ****************************

Call ( "Common.OpenList", Meta.Documents.Inventory );
Click ( "#FormCreate" );

form = With ( "Inventory (create)" );

Put ( "#Warehouse", warehouse );
Put ( "#Memo", id );

table = Activate ( "#ItemsTable" );
Click ( "#ItemsTableDelete" );

Click ( "#ItemsFill" );
question = App.FindObject ( Type ( "TestedForm" ), DialogsTitle );
//if ( question <> undefined ) then
//	Click ( "Yes");
//endif;

With ();
Click ( "Yes" );
With ();

p = Call ( "Common.Row.Params");
p.Table = table;
p.Column = "#ItemsQuantityPkg";
p.Row = 1;
Call ( "Common.Row", p );
table.ChangeRow ();
Set ( "#ItemsQuantityPkg", 100, table );
table.EndEditRow ();

p = Call ( "Common.Row.Params");
p.Table = table;
p.Column = "#ItemsQuantityPkg";
p.Row = 2;
Call ( "Common.Row", p );
table.ChangeRow ();
Set ( "#ItemsQuantity", 100, table );
table.EndEditRow ();

Click ( "#FormPost" );

