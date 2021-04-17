// Create a new Account
//
// Parameters:
// ChartsOfAccounts.General.Create.Params

Commando ( "e1cib/data/ChartOfAccounts.General" );
With ( "Chart of Accounts (cr*" );

Set ( "#Code", _.Code );
Set ( "#Order", _.Order );
Set ( "#Description", _.Description );
Put ( "#Type", _.Type );
Put ( "#Class", _.Class );

if ( _.Offbalance ) then
	Click ( "#OffBalance" );
endif;
if ( _.Quantitative ) then
	Click ( "#Quantitative" );
endif;
if ( _.Currency ) then
	Click ( "#Currency" );
endif;

Click ( "#FormWriteAndClose" );
