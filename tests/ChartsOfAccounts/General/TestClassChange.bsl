Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (create)" );
Put ( "#Class", "Accounts Payable" );
Check ( "#Type", "Liabilities" );

Put ( "#Class", "Accounts Receivable" );
Check ( "#Type", "Assets" );

Put ( "#Class", "Income" );
Check ( "#Type", "Liabilities" );