// Create a LVITransfer
// Create an Invoice Record
// Open LVITransfer and check if New Invoice button is not available
// Open Invoice Record and cancel it
// Open LVITransfer and check if New Invoice button is available
// Create second Invoice Record
// Open LVITransfer and print it
// Open list of transfers (checking if list works with two invoice records)

Call("Common.Init");
CloseAll();

id = Call ( "Common.ScenarioID", "2B670729" );

// Create a LVITransfer
transfer = Commando("e1cib/command/Document.LVITransfer.Create");


// Create an Invoice Record
Click("#NewInvoiceRecord");
With ();
Click("ok");
record = With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "AA" + id );
Set( "#DeliveryDate", "05/05/2020");
Click("#FormWrite");

// Open LVITransfer and check if New Invoice button is not available
With(transfer, true);
CheckState("#NewInvoiceRecord", "Visible", false);

// Open Invoice Record and cancel it
With(record, true);
Put("#Status", "Canceled");
Click("#FormWrite");

// Open LVITransfer and check if New Invoice button is available
With(transfer, true);
CheckState("#NewInvoiceRecord", "Visible");

// Create second Invoice Record
Pause(1);
Click("#NewInvoiceRecord");
With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "BB" + id );
Set( "#DeliveryDate", "05/05/2020");
Set("#Status", "Printed");
Click("#FormWrite");

// Open LVITransfer and print it (the last form should be printed)
With(transfer, true);
Click("#FormInvoice");
CheckErrors();

// Open list of transfer (checking if list works with two invoice records)
Commando("e1cib/list/Document.LVITransfer");

