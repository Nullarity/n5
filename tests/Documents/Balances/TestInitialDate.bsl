// Open balances list
// Set Balances Date
// Create a new Opening Balances document
// Fill, Post & Close that document
// Check if it shows in list

Call ( "Common.Init" );
CloseAll ();

// Open list
Commando ( "e1cib/list/DocumentJournal.Balances" );
list = With ( "Opening Balances" );

// Set Date
if ( Date ( Fetch ( "#BalanceDate" ) ) = Date ( 1, 1, 1 ) ) then
	date = Format ( CurrentDate (), "DLF=D" );
	Set ( "#BalanceDate", date );
	Next ();
endif;

// Create a new Opening Balance
Click ( "#FormCreateByParameterBalances" );
With ( "Opening Balances (cr*" );
Put ( "#Account", "11000" );
Set ( "Amount", 1000, Get ( "#Details" ) );
id = Call ( "Common.GetID" );
Set ( "#Memo", id );
Click ( "#FormPostAndClose" );

// Check if document exists
With ( list );
GotoRow ( Get ( "#List" ), "Memo", id );