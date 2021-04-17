// Create a new Customer
// Open Timesheets list
// Check if list is empty and Customer Filter is hidden

Call ( "Common.Init" );
CloseAll ();

// Create a new Customer
name = "Customer " + Call ( "Common.GetID" );
Commando ( "e1cib/data/Catalog.Organizations" );

With ( "Organizations (cr*" );
Set ( "#Description", name );
Click ( "#Customer" );
Click ( "#FormWrite" );

// Open Timesheets list
Click ( "Timesheets", GetLinks () ); 
With ( "Timesheets" );

// Check if list is empty and Customer Filter is hidden
CheckState ( "#CustomerFilter", "Visible", false );
count = Call ( "Table.Count", Get ( "#List" ) );
if ( count <> 0 ) then
	Stop ( "Tilesheet list should be filtered by " + name + " and should be empty!" );
endif;