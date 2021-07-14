Call ( "Common.Init" );
CloseAll ();

vendorName = "_Vendor create Vendor Invoice from list " + "A07K";

// ***********************************
// Create Vendor if new
// ***********************************

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Organizations;
p.Description = vendorName;
p.CreationParams = vendorName;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
Call ( "Common.CreateIfNew", p );

// ***********************************
// Open Vendors List
// ***********************************

OpenMenu ( "Purchases / Vendors" );
With ( "Vendors" );

p = Call ( "Common.Find.Params" );
p.Where = "Name";
p.What = vendorName;
Call ( "Common.Find", p );

Click ( "#FormDocumentVendorInvoiceNew" );

With ( "Vendor Invoice (cr*" );
Check ( "#Vendor", vendorName );