Call ( "Common.Init" );
CloseAll ();

// *********************
// Create Vendor Invoice
// *********************
Commando ( "e1cib/list/Document.VendorInvoice" );
invoicesList = With ( "Vendor Invoices" );
Click ( "#FormCreate" );
With ( "Vendor Invoice (cr*" );
Click ( "#FormWrite" );
number = Fetch ( "#Number" );
Close ();

// *********************
// Create Lot
// *********************
Commando ( "e1cib/list/Catalog.Lots" );
lotsList = With ( "Lots" );
Click ( "#FormCreate" );
formLot = With ( "Lots (cr*" );
Choose ( "#Document" );
With ( "Select data type" );
GotoRow ( "#TypeTree", "", "Vendor Invoice" );
Click ( "OK" );
With ( "Vendor Invoices" );
GotoRow ( "#List", "Number", number );
Click ( "#FormChoose" );
With ( formLot );
Click ( "#FormWrite" );
code = Fetch ( "#Code" );
Close ();

// *********************
// Mark for deletion
// *********************
With ( invoicesList );
Click ( "#FormSetDeletionMark" );
Click ( "Yes", "1?:*" );

// ************************************
// Check lot status: should be marked
// ************************************
With ( lotsList );
Click ( "#FormRefresh" );
Click ( "#FormSetDeletionMark" );
Get ( "Clear * deletion mark", "1?:*" ); // If title is found then deletion mark is correct
Click ( "No", "1?:*" );

// *********************
// Unmark for deletion
// *********************
With ( invoicesList );
Click ( "#FormSetDeletionMark" );
Click ( "Yes", "1?:*" );

// ************************************
// Check lot status: should be unmarked
// ************************************
With ( lotsList );
Click ( "#FormRefresh" );
Click ( "#FormSetDeletionMark" );
Get ( "Mark * for deletion", "1?:*" ); // If title is found then deletion mark is correct
Click ( "No", "1?:*" );
