// - Open a new Invoice
// - Choose customer account
// - Click twice on Show Offline button

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.Invoice" );
With ( "Invoice (cr*" );
Choose ( "#CustomerAccount" );

With ( "Chart of Accounts" );
Click ( "#FormShowOffline" );
Click ( "#FormShowOffline" );
