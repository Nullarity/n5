// Open chart of accounts list
// Enable view: tree
// Create ancestor
// Create subaccount

Call ( "Common.Init" );
CloseAll ();

id = Right ( Call ( "Common.GetID" ), 5 );
ancestor = "A" + id;
child = "B" + id;

// Create ancestor
Commando ( "e1cib/list/ChartOfAccounts.General" );
list = With ( "Chart of Accounts" );
Click ( "#FormTree" );

Click ( "#FormCreate" );
With ( "Chart of Accounts (cr*" );
Set ( "#Code", ancestor );
Set ( "#Description", ancestor );
Set ( "#Class", "Non-Posting" );
Clear ( "#Parent" );
Click ( "#FormWriteAndClose" );

// Create child
With ( list );
Click ( "#FormCreate" );
With ( "Chart of Accounts (cr*" );
Set ( "#Code", child );
Set ( "#Description", child );
Set ( "#Class", "Non-Posting" );
Click ( "#FormWrite" );
