MainWindow.ExecuteCommand ( "e1cib/data/Document.IntangibleAssetsWriteOff" );
form = With ( "Intangible Assets Write Off (create)" );
Put ( "#ExpenseAccount", "8111" );
Put ( "#Date", Format ( _.Date, "DLF=DT" ) );
Click ( "#ItemsFill" );
With ( "Fill*" );
Click ( "Fill" );
With ( form );
table = Activate ( "#Items" );
for each row in _.ExceptAssets do
	if ( GotoRow ( table, "Intangible Asset", row.Item, true ) ) then
		Click ( "#ItemsDelete" );
	endif;
enddo;
With ( form );
if ( Call ( "Table.Count", table ) = 0 ) then
	CloseAll ();
else
	// maybe filling data not found
	try
		Click ( "#FormPostAndClose" );
	except
		try
			With ( DialogsTitle );
			Click ( "OK" );
			CloseAll ();
		except
			CloseAll ();
		endtry;	
	endtry;
endif;
