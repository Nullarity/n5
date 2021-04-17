// - Open access rights
// - Remove all records
// - Create a new record
// - Check controls
// - Save and Close
// - Open again
// - Close
// - Try to copy
// - Close
// - Remove all records

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/InformationRegister.Rights" );
list = With ( "Access to Documents" );

// Remove all records
removeAll ();

// Create a new record
Click ( "#FormCreate" );
With ( "Rights (cr*" );

// Check default status
CheckState ( "#Duration", "Enable", false );

// Check new status
Set ( "#MethodDuration", "Restrict access based on number of passed days" );
CheckState ( "#Duration", "Enable" );

// Save & Close
Click ( "#FormWriteAndClose" );

// Open again
With ( list );
Click ( "#FormChange" );
With ( "Rights" );
Close ();

// Try to copy
With ( list );
Click ( "#FormCopy" );
With ( "Rights (cr*" );
Close ();

// Remove
removeAll ();

Procedure removeAll ()

	With ( "Access to Documents" );
	table = Get ( "#List" );
	table.GotoFirstRow ();
	if ( table.GetSelectedRows ().Count () > 0 ) then
		table.SelectAllRows ();
		table.DeleteRow ();
		Click ( "Yes", "1?:*" );
	endif;

EndProcedure
