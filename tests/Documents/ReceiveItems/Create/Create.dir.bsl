StandardProcessing = false;

MainWindow.ExecuteCommand ( "e1cib/data/Document.ReceiveItems" );
form = With ( "Receive Items (create)" );

Set ( "#Date", Format ( _.Date, "DLF=DT" ) );
Set ( "#Warehouse", _.Warehouse );
Put ( "#Account", _.Account );
Set ( "#Memo", _.ID );

table = Activate ( "#Items" );

for each row in _.Items do
	Click ( "#ItemsAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	if ( row.Account <> undefined ) then
		Set ( "#ItemsAccount", row.Account, table );
	endif;
	Set ( "#ItemsPrice", row.Price, table );
	if ( Call ( "Common.AppIsCont" ) ) then
		if ( row.Social ) then
			Set ( "#ItemsProducerPrice", row.ProducerPrice, table );
		endif;
	endif;
enddo;

table = Activate ( "#FixedAssets" );
for each row in _.FixedAssets do
	Click ( "#FixedAssetsAdd" );
	With ( "Fixed Asset" );
	Set ( "#Item", row.Item );
	Set ( "#Amount", row.Amount );
	Set ( "#Employee", row.Employee );
	Set ( "#Department", row.Department );
	Set ( "#Method", row.Method );
	if ( row.Shedule <> undefined ) then
		Set ( "#Schedule", row.Shedule );
	endif;
	Set ( "#UsefulLife", row.UsefulLife );
	if ( row.Charge ) then
		Click ( "#Charge" );
	endif;	
	Set ( "#Starting", Format ( row.Starting, "DLF=DT" ) );
	Set ( "#LiquidationValue", row.LiquidationValue );
	if ( row.Expenses <> undefined ) then
		Set ( "#Expenses", row.Expenses );
	endif;
	Click ( "#FormOK" );
	With ( form );
enddo;

table = Activate ( "#IntangibleAssets" );
for each row in _.IntangibleAssets do
	Click ( "#IntangibleAssetsAdd" );
	With ( "Intangible Asset" );
	Set ( "#Item", row.Item );
	Set ( "#Amount", row.Amount );
	Set ( "#Employee", row.Employee );
	Set ( "#Department", row.Department );
	Set ( "#Method", row.Method );
	Set ( "#UsefulLife", row.UsefulLife );
	if ( row.Charge ) then
		Click ( "#Charge" );
	endif;	
	if ( row.Expenses <> undefined ) then
		Set ( "#Expenses", row.Expenses );
	endif;
	Set ( "#Starting", Format ( row.Starting, "DLF=DT" ) );
	Click ( "#FormOK" );
	With ( form );
enddo;

if ( _.Post ) then
	Click("#FormPostAndClose");
endif;