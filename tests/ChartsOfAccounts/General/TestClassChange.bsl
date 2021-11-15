Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (create)" );
Put ( "#Class", "Accounts Payable" );
Check ( "#Type", "Passive" );

Put ( "#Class", "Accounts Receivable" );
Check ( "#Type", "Active" );

Put ( "#Class", "Income" );
Check ( "#Type", "Passive" );