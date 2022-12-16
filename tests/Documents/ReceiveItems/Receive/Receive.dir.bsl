MainWindow.ExecuteCommand ( "e1cib/data/Document.ReceiveItems" );

form = With ( "Receive Items (create)" );

Set ( "Date", _.Date );

if ( _.Company <> undefined ) then
	Put ( "#Company", _.Company );
endif;

if ( _.Warehouse <> undefined ) then
	Choose ( "#Warehouse" );
	
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Warehouses;
	p.Search = _.Warehouse;
	p.CreateScenario = "Catalogs.Warehouses.Create";
	Call ( "Common.Select", p );
	
	With ( form );
	Set ( "#Warehouse", _.Warehouse );
endif;
Set ( "#Account", _.Account );
form.GotoNextItem ();
if ( _.Memo <> undefined ) then
	Set ( "#Memo", _.Memo );
endif;

if ( _.Expenses <> undefined ) then
	Choose ( "#Dim1" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Expenses;
	p.Search = _.Expenses;
	p.CreateScenario = "Catalogs.Expenses.Create";
	Call ( "Common.Select", p );
endif;

With ( form );

// ***********************
// Items
// ***********************

table = Activate ( "#Items" );

for each row in _.Items do
	Click ( "#ItemsAdd" );
	
	Choose ( "#ItemsItem" );
	name = row.Item;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.Items;
	params.Search = name;
	creation = Call ( "Catalogs.Items.Create.Params" );
	creation.Description = name;
	creation.CountPackages = row.CountPackages;
	params.CreationParams = creation;
	params.CreateScenario = "Catalogs.Items.Create";
	Call ( "Common.Select", params );
	
	With ( form );

    Set ( "#ItemsItem", name, table );
    if ( row.UseItemsQuantityPkg ) then
    	Set ( "#ItemsQuantityPkg", row.Quantity, table );
    else
    	Set ( "#ItemsQuantity", row.Quantity, table );
    endif;
	Set ( "#ItemsPrice", row.Price, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
enddo;

// ***********************
// Items
// ***********************

table = Activate ( "#IntangibleAssets" );
for each row in _.IntangibleAssets do

	Click ( "#IntangibleAssetsAdd" );
	
	With ( "Intangible Asset" );
	Set ( "#Item", row.Asset );
	Set ( "#Amount", row.Amount );
	Set ( "#Department", row.Department );
	Set ( "#Employee", row.Responsible );
	Set ( "#Method", row.Method );
	Set ( "#UsefulLife", row.UsefulLife );
	Put ( "#Expenses", _.Expenses );
	if ( row.Charge ) then
		Click ( "#Charge" );
	endif;
	value = row.Starting;
	if ( value <> undefined ) then
		Set ( "#Starting", value );
	endif;
	Click ( "#FormOK" );

	With ( form );

enddo;

Click ( "Post and close" );
