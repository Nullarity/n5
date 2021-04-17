// - Create a new Customer
// - Save it
// - Open Customer Operations
// - Create Invoice and check Customer field

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.Organizations" );
With ( "*cr*)" );

name = Call ( "Common.GetID" ) + " " + CurrentDate ();
Set ( "#Description", name );
Click ( "#Customer" );
Click ( "#FormWrite" );
Click ( "Customer Operations", GetLinks () );

With ( "Customer Operations" );
Click ( "#FormCreateByParameterInvoice" );
Check ( "#Customer", name, "Invoice (cr*" );
