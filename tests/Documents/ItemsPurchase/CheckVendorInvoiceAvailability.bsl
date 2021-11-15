// Create an Invoice
// Create an Invoice Record and print it
// Check if Invoice is not available for changes anymore

Call("Common.Init");
CloseAll();

id = Call ( "Common.ScenarioID", "2B8A8920" );

// Create an Invoice
invoice = Commando("e1cib/command/Document.Invoice.Create");
CheckState("#ItemsSelectItems, #ItemsScan, #ItemsApplySalesOrders", "Enable");
Put ("#Customer","Customer");
Click("#JustSave");

// Create an Invoice Record and print it
Click("#NewInvoiceRecord");
record = With();
Set ( "#Number", ID );
Click("#FormWrite");
Click("#FormPrint");
Close();

// Check if Invoice is not available for changes anymore
With(invoice, true);
CheckState("#ItemsSelectItems, #ItemsScan, #ItemsApplySalesOrders", "Enable", false);

