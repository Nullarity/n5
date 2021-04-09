Call ( "Common.Init" );
CloseAll ();

vendorName = "_Vendor create PO from list#";

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

Click ( "#FormDocumentPurchaseOrderNew" );

With ( "Purchase Order (cr*" );
Check ( "#Vendor", vendorName );