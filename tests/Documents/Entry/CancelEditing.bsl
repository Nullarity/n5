// Create Entry, Add Record, Cancel Record
// Check rows count = 0
// Add & Commin another record
// Edit & Cancel
// Check rows count = 1
// Copy & Cancel

Call ( "Common.Init" );

// Create Entry
Commando ( "e1cib/data/Document.Entry" );
With ( "Entry (cr*" );
Click ( "#RecordsAdd" );

// Cancel Record
Close ( "Record" );

// Check rows count
table = Get ( "#Records" );
count = Call ( "Table.Count", table );
if ( count > 0 ) then
	Stop ( "Record was canceled but still exists in the list" );
endif;

// Add & Commin another record
Click ( "#RecordsAdd" );
Click ( "#FormOK", "Record" );

// Edit & Cancel
Click ( "#RecordsEdit" );
Close ( "Record" );

// Check rows count
count = Call ( "Table.Count", table );
if ( count <> 1 ) then
	Stop ( "Only one record should be in the list" );
endif;

// Copy & Cancel
Click ( "#RecordsCopy" );
Close ( "Record" );
