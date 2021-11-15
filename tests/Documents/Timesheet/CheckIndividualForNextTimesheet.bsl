// Create & save a new Timesheet
// In the Timesheet window, click Next button and create another new Timesheet
// Save the new Timesheet
// Open records and check if Individual field is populated

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.Timesheet" );
With ( "Timesheet (cr*" );

Click ( "#FormWrite" );
Click ( "#NextPeriod" );
Click ( "#FormWrite" );

Click ( "#FormReportRecordsOpen" );

With ( "Records: T*" );

individual = Fetch ( "#TabDoc [ R10C6 ]" );
if ( IsBlankString ( individual ) ) then
	Stop ( "The Individual field must be filled" );
endif;