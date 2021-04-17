// Open Balance Sheet report
// Click commands: ShowGroups, ShowGrid

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/app/Report.BalanceSheet" );
With ( "Balance Sheet*" );

Click ( "#ShowGrid" );
Click ( "#ShowGrid" );
Click ( "#ShowHeaders" );
Click ( "#ShowHeaders" );
