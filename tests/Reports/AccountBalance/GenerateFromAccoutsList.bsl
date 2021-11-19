Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/ChartOfAccounts.General" );
GotoRow ( Get ( "#List" ), "Code", "2211" );

Click ( "#FormReportAccountBalanceShow" );
