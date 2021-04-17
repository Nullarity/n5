// Create an Invoice
// Create an Invoice Record
// Open Invoice and check if New Invoice button is not available
// Open Invoice Record and cancel it
// Open Invoice and check if New Invoice button is available
// Create second Invoice Record
// Open Invoice and print it
// Open list of invoices (checking if list works with two invoice records)

Call("Common.Init");
CloseAll();

id = Call ( "Common.ScenarioID", "2B670684" );

// Create an Invoice
invoice = Commando("e1cib/command/Document.Invoice.Create");
Put ( "#Customer", "Customer" );
Click ( "#JustSave" );

// Create an Invoice Record
Click("#NewInvoiceRecord");
record = With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "AA" + id );
Click("#FormWrite");

// Open Invoice and check if New Invoice button is not available
With(invoice, true);
CheckState("#NewInvoiceRecord", "Visible", false);

// Open Invoice Record and cancel it
With(record, true);
Put("#Status", "Canceled");
Click("#FormWrite");

// Open Invoice and check if New Invoice button is available
With(invoice, true);
CheckState("#NewInvoiceRecord", "Visible");

// Create second Invoice Record
Pause(1);
Click("#NewInvoiceRecord");
With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "BB" + id );
Set("#Status", "Printed");
Click("#FormWrite");

// Open Invoice and print it (the last form should be printed)
With(invoice, true);
Click("#FormInvoice");
CheckErrors ();

// Open list of invoices (checking if list works with two invoice records)
Commando("e1cib/list/Document.Invoice");

