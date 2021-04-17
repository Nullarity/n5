// Test Method: DateToTime ()

Run ( "Attach" );
lib = new ( "AddIn.Core.Conversion" );
date = CurrentDate ();
time = lib.DateToTime ( date );
rightTime = Date ( 1, 1, 1 ) + Hour ( date ) * 3600 + Minute ( date ) * 60 + Second ( Date );
if ( time <> rightTime ) then
	Stop ( "DateToTime () returns " + time + ", but result should be:" + rightTime );
endif;
