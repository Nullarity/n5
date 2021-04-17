Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.Payroll" );

With ( "Payroll (cr*" );

// Check monthly period
selectPeriod ( "Month" );
dateStart = Date ( Fetch ( "#DateStart" ) );
dateEnd = Date ( Fetch ( "#DateEnd" ) );

if ( dateEnd <> EndOfMonth ( dateStart ) ) then
	Stop ( "DateStart and DateEnd should define monthly period" );
endif;
CheckState ( "#PreviousPeriod, #NextPeriod", "Visible" );
CheckState ( "#DateStart", "ReadOnly" );

// Check weekly period
selectPeriod ( "Week" );
dateStart = Date ( Fetch ( "#DateStart" ) );
dateEnd = Date ( Fetch ( "#DateEnd" ) );

duration = ( dateEnd - dateStart ) / 86400;
if ( 7 <> duration ) then
	Stop ( "DateStart and DateEnd should have 7 days difference" );
endif;
CheckState ( "#PreviousPeriod, #NextPeriod", "Visible" );

// Check biweekly period
selectPeriod ( "Two Weeks" );
dateStart = Date ( Fetch ( "#DateStart" ) );
dateEnd = Date ( Fetch ( "#DateEnd" ) );

duration = ( dateEnd - dateStart ) / 86400;
if ( 14 <> duration ) then
	Stop ( "DateStart and DateEnd should have 14 days difference" );
endif;
CheckState ( "#PreviousPeriod, #NextPeriod", "Visible" );

// Check other period
selectPeriod ( "Other" );
CheckState ( "#PreviousPeriod, #NextPeriod", "Visible", false );

Disconnect ();

// **********************
// Procedures
// **********************

Procedure selectPeriod ( Period )

	f = Activate ( "#Period" );
	f.OpenDropList ();
	Click ( "Yes", "1?:*" );
	Pick ( "#Period", Period );

EndProcedure
