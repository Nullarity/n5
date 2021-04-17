// - Open Accounts list
// - Calc total rows in the list (A)
// - Click Show Offile
// - Create offline account
// - Calc total rows in the list (B)
// - Check if A < B

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/ChartOfAccounts.General" );
list = With ( "Chart of Accounts" );

// Calc active accounts (A)
table = Get ( "#List" );
activeRows = Call ( "Table.Count", table );

// Show offline accounts & create another one
Click ( "#FormShowOffline" );
Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (cr*" );
id = Call ( "Common.GetID" );
Set ( "#Code", id );
Set ( "#Description", id );
Set ( "#Class", "Non-Posting" );
Click ( "#Offline" );
Click ( "#FormWriteAndClose" );

// Calc all rows (B) and check if A < B
With ( list );
allRows = Call ( "Table.Count", table );
if ( activeRows >= allRows ) then
	Stop ( "Filter by Offline accounts does not work!" );
endif;
