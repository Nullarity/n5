Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.Payroll" );
form = With ( "Payroll (cr*" );

Click ( "#CompensationsAdd" );
Click ( "OK", "Compensation" );
Click ( "#PreviousPeriod" );
Click ( "Yes", DialogsTitle );

Click ( "#CompensationsAdd" );
Click ( "OK", "Compensation" );
Click ( "#NextPeriod" );
Click ( "Yes", DialogsTitle );
