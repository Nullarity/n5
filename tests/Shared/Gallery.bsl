// Description:
// Test embedded items gallery
// Parameters:
// P1: Document metadata

itemName = "_Item for Gallery#";
Call ( "Catalogs.Items.CreateIfNew", itemName );

MainWindow.ExecuteCommand ( "e1cib/data/Document." + _.Name );
With ( _.Synonym + " (create)" );

table = Activate ( "#ItemsTable" ); 
Click ( "#ItemsTableAdd" );
Set ( "#ItemsItem", itemName, table );
try
	Set ( "#ItemsQuantityPkg", "1", table );
except
	DebugStart ();
endtry;
f = Get ( "#Resize" );
if ( f.CurrentVisible () ) then
	Click ( "#Resize" );
endif;
Click ( "#ItemsShowPictures" );
if ( f.CurrentVisible () ) then
	Click ( "#Resize" );
endif;
Click ( "#ItemsShowPictures" );

