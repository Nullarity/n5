StandardProcessing = false;

MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorInvoice" );
form = With ( "Vendor Invoice (create)" );

if ( AppName <> "Cont5" ) then
	Put ( "#TaxGroup", _.TaxGroup );
endif;	
Put ( "#Date", _.Date );
Put ( "#Vendor", _.Vendor );
Put ( "#Warehouse", _.Warehouse );
Put ( "#Memo", _.ID );

table = Activate ( "#ItemsTable" );
for each row in _.Items do
	Click ( "#ItemsTableAdd" );
	//table.EndEditRow (); // Otherwise platform hangs up (it will add infinitive number of rows)
	Put ( "#ItemsItem", row.Item, table );
	Next ();
	Pause (3);
	Put ( "#ItemsQuantity", row.Quantity, table );
	Pause (3);
	if ( row.Account <> undefined ) then
		Put ( "#ItemsAccount", row.Account, table );
	endif;
	if ( Call ( "Common.AppIsCont" ) ) then
		if ( row.Social ) then
			Put ( "#ItemsProducerPrice", row.ProducerPrice, table );
		endif;
	endif;
	Put ( "#ItemsPrice", row.Price, table );
enddo;

table = Activate ( "#Services" );
for each row in _.Services do
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", row.Item, table );
	Put ( "#ServicesQuantity", row.Quantity, table );
	Put ( "#ServicesPrice", row.Price, table );
	Put ( "#ServicesExpense", row.Expense, table );
	Put ( "#ServicesAccount", row.Account, table );
	Put ( "#ServicesDepartment", row.Department, table );
enddo;

table = Activate ( "#FixedAssets" );
for each row in _.FixedAssets do
	Click ( "#FixedAssetsAdd" );
	With ( "Fixed Asset" );
	Put ( "#Item", row.Item );
	Put ( "#Amount", row.Amount );
	Put ( "#Employee", row.Employee );
	Put ( "#Department", row.Department );
	Click ( "#FormOK" );
	With ( form );
enddo;

table = Activate ( "#IntangibleAssets" );
for each row in _.IntangibleAssets do
	Click ( "#IntangibleAssetsAdd" );
	With ( "Intangible Asset" );
	Put ( "#Item", row.Item );
	Put ( "#Amount", row.Amount );
	Put ( "#Employee", row.Employee );
	Put ( "#Department", row.Department );
	Click ( "#FormOK" );
	With ( form );
enddo;

table = Activate ( "#Accounts" );
for each row in _.Accounts do
	Click ( "#AccountsAdd" );
	Put ( "#AccountsAccount", row.Account, table );
	Put ( "#AccountsAmount", row.Amount, table );
	try
		Put ( "#AccountsDim1", row.Dim1, table );
		Put ( "#AccountsDim2", row.Dim2, table );
		Put ( "#AccountsDim3", row.Dim3, table );
	except
	endtry;	
	Put ( "#AccountsAmount", row.Amount, table );
	Call ( "Table.AddEscape", table );
enddo;

