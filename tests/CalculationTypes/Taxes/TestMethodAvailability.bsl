Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfCalculationTypes.Taxes" );
form = With ( "Taxes (cr*" );

id = Call ( "Common.ScenarioID", "2D0920C1" );

Set ( "#Method", "Income Tax (scale)" );
Set ( "#Account", "5333" );
Set ( "#Code", id );

CheckState ( "#Warning", "Visible" );
CheckState ( "#Method", "Enable" );

Put ( "#Description", id );

Click ( "#Write" );

CheckState ( "#Warning", "Visible", false );
CheckState ( "#Method", "Enable", false );
