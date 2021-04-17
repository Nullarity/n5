Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.VendorPayment );

Choose ( "#VendorFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
p.Search = "_Vendor";
Call ( "Common.Select", p );

With ( form );
vendor = Fetch ( "#VendorFilter" );

Click ( "#FormCreate" );

With ( "Vendor Payment (create)" );
Check ( "#Vendor", vendor );
