// - Open list
// - Remove all records
// - Create a new record
// - Save and Close
// - Remove all records

Call ( "Common.Init" );
CloseAll ();

// Open list
Commando ( "e1cib/list/InformationRegister.Rights" );
list = With ( "Access to Documents" );

// Remove all records
removeAll ();

// Set Owner
Click ( "#OwnershipCreate" );
form = With ( "Rights Ownership (cr*" );
Put ( "#Owner", "admin" );

// Set Target
Choose ( "#Target" );
Click ( "#OK", "Select data type" );
With ( "Groups" );
GotoRow ( "#List", "Description", "Users" );
Click ( "#FormChoose" );

// Save & Close
With ( form );
Click ( "#FormWriteAndClose" );

// Remove all records
removeAll ();

Procedure removeAll ()

	With ( "Access to Documents" );
	table = Get ( "#Ownership" );
	table.GotoFirstRow ();
	if ( table.GetSelectedRows ().Count () > 0 ) then
		table.SelectAllRows ();
		table.DeleteRow ();
		Click ( "Yes", "1?:*" );
	endif;

EndProcedure
