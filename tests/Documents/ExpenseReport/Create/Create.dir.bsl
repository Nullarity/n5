StandardProcessing = false;

Commando ( "e1cib/data/Document.ExpenseReport" );
form = With ( "Expense Report (create)" );

Put ( "#Date", _.Date );
Put ( "#Warehouse", _.Warehouse );
Put ( "#Employee", _.Employee );
Put ( "#Memo", _.ID );

cont = Call ( "Common.AppIsCont" );
if ( cont ) then
	Put ( "#VATUse", "Included in Price" );
else
	Put ( "#TaxGroup", _.TaxGroup );	
endif;

table = Activate ( "#ItemsTable" );

for each row in _.Items do
	Click ( "#ItemsTableAdd" );
	//table.EndEditRow ();
	Put ( "#ItemsItem", row.Item, table );
	Next ();
	Put ( "#ItemsQuantity", row.Quantity, table );
	if ( row.Account <> undefined ) then
		Put ( "#ItemsAccount", row.Account, table );
	endif;
	Put ( "#ItemsPrice", row.Price, table );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#ItemsType", "Invoice", table );
		Put ( "#ItemsDate", row.Date, table );
		Put ( "#ItemsNumber", row.Number, table );
		if ( row.Social ) then
			Put ( "#ItemsProducerPrice", row.ProducerPrice, table );
		endif;
	endif;
enddo;

table = Activate ( "#Services" );
for each row in _.Services do
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", row.Item, table );
	Next ();
	Put ( "#ServicesQuantity", row.Quantity, table );
	Put ( "#ServicesPrice", row.Price, table );
	Put ( "#ServicesExpense", row.Expense, table );
	Put ( "#ServicesAccount", row.Account, table );
	Put ( "#ServicesDepartment", row.Department, table );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#ServicesType", "Invoice", table );
		Put ( "#ServicesDate", row.Date, table );
		Put ( "#ServicesNumber", row.Number, table );
	endif;
enddo;

table = Activate ( "#FixedAssets" );
for each row in _.FixedAssets do
	Click ( "#FixedAssetsAdd" );
	With ( "Fixed Asset" );
	Put ( "#Item", row.Item );
	Next ();
	Put ( "#Amount", row.Amount );
	Put ( "#Employee", row.Employee );
	Put ( "#Department", row.Department );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#Type", "Invoice" );
	endif;	
	Click ( "#FormOK" );
	With ( form );
enddo;

table = Activate ( "#IntangibleAssets" );
for each row in _.IntangibleAssets do
	Click ( "#IntangibleAssetsAdd" );
	With ( "Intangible Asset" );
	Put ( "#Item", row.Item );
	Next ();
	Put ( "#Amount", row.Amount );
	Put ( "#Employee", row.Employee );
	Put ( "#Department", row.Department );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#Type", "Invoice" );
	endif;	
	Click ( "#FormOK" );
	With ( form );
enddo;

table = Activate ( "#Accounts" );
for each row in _.Accounts do
	Click ( "#AccountsAdd" );
	Put ( "#AccountsAccount", row.Account, table );
	Next ();
	Put ( "#AccountsAmount", row.Amount, table );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#AccountsType", "Invoice", table );
		Put ( "#AccountsDate", row.Date, table );
		Put ( "#AccountsNumber", row.Number, table );
	endif;
	Put ( "#AccountsContent", row.Content, table );
	try
		Put ( "#AccountsDim1", row.Dim1, table );
		Put ( "#AccountsDim2", row.Dim2, table );
		Put ( "#AccountsDim3", row.Dim3, table );
	except
	endtry;	
	Put ( "#AccountsAmount", row.Amount, table );
	if ( cont ) then
		Put ( "#AccountsVATCode", "20%", table );
		Put ( "#AccountsVATAccount", "5345" );
	endif;
	Call ( "Table.AddEscape", table );
enddo;



