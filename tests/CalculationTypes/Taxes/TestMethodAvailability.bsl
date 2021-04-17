Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfCalculationTypes.Taxes" );
form = With ( "Taxes (cr*" );

id = Call ( "Common.GetID" );//Call ( "Common.ScenarioID", "27387713#" );

Set ( "#Method", "Income Tax (scale)" );
Set ( "#Account", "24010" );
Set ( "#Code", id );

CheckState ( "#Warning", "Visible" );
CheckState ( "#Method", "Enable" );

Put ( "#Description", id );

Click ( "#Write" );

CheckState ( "#Warning", "Visible", false );
CheckState ( "#Method", "Enable", false );
