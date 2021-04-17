Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfCalculationTypes.Compensations" );
With ( "Compensations (cr*" );

Pick ( "#Method", "Monthly Rate" );
Clear ( "#HourlyRate" );

IgnoreErrors = true;

Click ( "#FormWrite" );
Call ( "Common.CheckFillingError", "*Hourly Rate*" );
CloseAll ();

IgnoreErrors = false;
