// Create a Transfer
// Create an Invoice Record and print it
// Check if Transfer is not available for changes anymore

Call("Common.Init");
CloseAll();

// Create a Transfer
transfer = Commando("e1cib/command/Document.Transfer.Create");
CheckState("#ItemsSelectItems, #ItemsScan", "Enable");
Click("#JustSave");

// Create an Invoice Record and print it
Click("#NewInvoiceRecord");
record = With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "AA" + Call ( "Common.ScenarioID", "2B6AD83A" ) );
Set ("#DeliveryDate", "05/20/2020");
Click("#FormWrite");
Click("#FormPrint");
Close();

// Check if Transfer is not available for changes anymore
With(transfer, true);
CheckState("#ItemsSelectItems, #ItemsScan", "Enable", false);

