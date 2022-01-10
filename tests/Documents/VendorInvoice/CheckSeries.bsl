// Set document number and check series exctraction

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Reference", "ABC123");
Next ();
Check("#Series", "ABC");
Set("#Reference", " ABC-123 ");
Next ();
Check("#Reference", "ABC123");
Check("#Series", "ABC");