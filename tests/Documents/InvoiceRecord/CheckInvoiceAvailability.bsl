// Create an Invoice
// Create an Invoice Record and print it
// Check if Invoice is not available for changes anymore

Call("Common.Init");
CloseAll();

// Create an Invoice
invoice = Commando("e1cib/command/Document.Invoice.Create");
CheckState("#ItemsSelectItems, #ItemsScan, #ItemsApplySalesOrders", "Enable");
Put ( "#Customer", "Customer" );
Click("#JustSave");

// Create an Invoice Record and print it
Click("#NewInvoiceRecord");
record = With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "" + new UUID () );
Click("#FormWrite");
try
	Click("#FormPrint");
except
	DebugStart ();
endtry;
Close();

// Check if Invoice is not available for changes anymore
With(invoice, true);
CheckState("#ItemsSelectItems, #ItemsScan, #ItemsApplySalesOrders", "Enable", false);


