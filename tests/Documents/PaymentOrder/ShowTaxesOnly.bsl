// Open list and filter by Taxes Only

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/list/Document.PaymentOrder");
Click ( "#TaxesOnly" );
Pause ( 3 );
Click ( "#TaxesOnly" );