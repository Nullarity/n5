// Create a LVITransfer
// Create an Invoice Record and print it
// Check if Transfer is not available for changes anymore

Call("Common.Init");
CloseAll();

// Create an Invoice
transfer = Commando("e1cib/command/Document.LVITransfer.Create");

// Create an Invoice Record and print it
Click("#NewInvoiceRecord");
With ();
Click ( "OK" );
record = With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "AA" + Call ( "Common.ScenarioID", "2B6AD82D" ) );
Set ( "#DeliveryDate", "05/20/2020" );
Pause (5);
Click("#FormWrite");
Click("#FormPrint");
Close();

// Check if Invoice is not available for changes anymore
With(transfer, true);
CheckState("#GroupItems", "ReadOnly");

