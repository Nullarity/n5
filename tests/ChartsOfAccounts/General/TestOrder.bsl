Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (create)" );
code = "1234";
Set ( "#Code", code );
Activate ( "#Order" );
Check ( "#Order", code );