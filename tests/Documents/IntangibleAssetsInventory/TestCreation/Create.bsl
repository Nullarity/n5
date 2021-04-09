//
env = Call ( "Documents.IntangibleAssetsWriteOff.GetEnv", _ );

Commando ( "e1cib/data/Document.IntangibleAssetsInventory" );
form = With ( "Intangible Assets Inventory (create)" );

table = Activate ( "#ItemsTable" );
table.EndEditRow ();

Set ( "#Department", Env.Department );
Set ( "#Employee", Env.Responsible );
Put ( "#Memo", env.ID );

Click ( "#ItemsFill" );
//question = App.FindObject ( Type ( "TestedForm" ), DialogsTitle );
//if ( question <> undefined ) then
//	Click ( "Yes", question );
//endif;
With ();
Click ( "Yes" );
With ();
Click ( "#ItemsTableDelete" ); // Delete empty row

// *************************
// Change some fields
// *************************

Click ( "#ItemsAvailability" );
Set ( "#ItemsAmount [ 2 ]", "300", table );

// *************************
// Check table
// *************************

Click ( "#ItemsTableOutputList" );
With ( "Display list" );
Click ( "#Ok" );

With ( "List" );
CheckTemplate ( "" ); // List does not have title or id

// *************************
// Enter Write Off
// *************************

With ( form );
Click ( "#FormDocumentIntangibleAssetsWriteOffCreateBasedOn" );
Click ( "OK", "1?:*" );
formAssets = With ( "Intangible Assets Write *" );
Put ( "#ExpenseAccount", env.ExpenseAccount );
Set ( "Expenses", env.Expense );
Put ( "#Memo", _ );
Click ( "#FormPost" );
Close ( formAssets );

// *************************
// Enter Receive Items
// *************************

With ( form );
Click ( "#FormDocumentReceiveItemsCreateBasedOn" );
form = With ( "Receive Items *" );
if ( Call ( "Common.AppIsCont" ) ) then
	Put ( "#Account", "2111" );
else
	Put ( "#Account", "12100" );
endif;
Put ( "#Warehouse", env.Warehouse );
Click ( "#FormPost" );



