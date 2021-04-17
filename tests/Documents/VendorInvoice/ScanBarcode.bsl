// Create Barcode and pick it in Invoice

Call ( "Common.Init" );
CloseAll ();

item = "Item " + Call("Common.GetID");

// Create Item and Barcode
Commando("e1cib/command/Catalog.Items.Create");
With();
Set("#Description", item);
Click("Barcodes", GetLinks());
Click("OK", "1?:*");
With();
Click("#FormCreate");
With();
Click("#FormNewEAN13");
barcode = Fetch("#Barcode");
Click("#FormWriteAndClose");

// Create Vendor Invoice and pick item by barcode
Commando("e1cib/command/Document.VendorInvoice.Create");
With();
Click("#ItemsScan");
With();
Set("#Barcode", barcode);

With("Quantity");
Click("#FormOK");