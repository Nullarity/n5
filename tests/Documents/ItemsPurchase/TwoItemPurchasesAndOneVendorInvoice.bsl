// Create a VendorInvoice
// Create an Items Purchase
// Open VendorInvoice and check if New Items Purchase button is not available
// Open Items Purchase and cancel it
// Open VendorInvoice and check if New Items Purchase button is available
// Create second Items Purchase
// Open VendorInvoice and print it
// Open list of transfers (checking if list works with two invoice records)

Call("Common.Init");
CloseAll();

id = Call ( "Common.ScenarioID", "2B67065C" );

// Create a VendorInvoice
transfer = Commando("e1cib/command/Document.VendorInvoice.Create");
Click("#JustSave");

// Create an Items Purchase
Click ( "#FormDocumentItemsPurchaseCreateBasedOn" );
record = With();
Click( "#FormPost" );



// Open VendorInvoice and check if New Items Purchase button is not available
With(transfer, true);
CheckState("#FormItemsPurchase", "Visible", false);

// Open Items Purchase and cancel it
With(record, true);
Put("#Status", "Canceled");
With( "Items Purchase (cr*)" );
Set( "#Number", "AA" + id );
With();
Click ( "Yes" );
With( "Items Purchase (cr*)" );
Activate ( "#PageMore" );
Put ("#Responsible","Responsible");
Click("#FormPost");

// Open VendorInvoice and check if New Items Purchase button is available
With(transfer, true);
CheckState("#FormItemsPurchase", "Visible");

// Create second Items Purchase
Click("#FormDocumentItemsPurchaseCreateBasedOn");
With();
Set("#Status", "Printed");
With( "Items Purchase (cr*)" );
Set( "#Number", "AB" + id );
With();
Click ( "Yes" );
With( "Items Purchase (cr*)" );
Activate ( "#PageMore" );
Put ("#Responsible","Responsible");
Click("#FormPost");

// Open VendorInvoice and print it (the last form should be printed)
With(transfer, true);
Click("#FormItemsPurchase");
CheckErrors();

// Open list of transfer (checking if list works with two invoice records)
Commando("e1cib/list/Document.VendorInvoice");

