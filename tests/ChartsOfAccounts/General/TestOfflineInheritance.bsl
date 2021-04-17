// - Create offline account A
// - Create subaccount B
// - Check if account B becomes offline too

Call ( "Common.Init" );
CloseAll ();

id = Right ( Call ( "Common.GetID" ), 5 );
ancestor = "A" + id;
child = "B" + id;

// Create ancestor
Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (cr*" );
Set ( "#Code", ancestor );
Set ( "#Description", ancestor );
Set ( "#Class", "Non-Posting" );
Click ( "#Offline" );
Click ( "#FormWriteAndClose" );

// Create child
Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (cr*" );
Set ( "#Code", child );
Set ( "#Description", child );
Set ( "#Class", "Non-Posting" );
Click ( "#FormWrite" );

Check ( "#Offline", "No" );

// Make it as subaccount
Set ( "#Parent", ancestor );
Click ( "#FormWrite" );
Check ( "#Offline", "Yes" );

// Remove inheritance
Clear ( "#Parent" );
Click ( "#FormWrite" );
Check ( "#Offline", "Yes" ); // Flag should stay
