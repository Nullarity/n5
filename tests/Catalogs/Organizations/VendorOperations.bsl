// - Create a new Vendor
// - Save it
// - Open Vendor Operations
// - Create Vendor Invoice and check Vendor field

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.Organizations" );
With ( "*cr*)" );

name = Call ( "Common.GetID" ) + " " + CurrentDate ();
Set ( "#Description", name );
Click ( "#Vendor" );
Click ( "#FormWrite" );
Click ( "Vendor Operations", GetLinks () );

With ( "Vendor Operations" );
Click ( "#FormCreateByParameterVendorInvoice" );
Check ( "#Vendor", name, "Vendor Invoice (cr*" );